# https://keras.io/examples/generative/vae/
import os, json
import pickle

import numpy as np
import pandas as pd

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

from sklearn.model_selection import train_test_split
#from sklearn.preprocessing import OneHotEncoder
from keras.utils.np_utils import to_categorical   



import matplotlib.pyplot as plt

# CNN require huge amounts of RAM, specially during training
# Computational requirements for a single CNN layer:
#     - Number of parameters: (+1 is the bias term)
#         (filter width * filter height * channels + 1 ) * feature maps 
#     - Number of float multiplications:
#         feature maps * feature map width * feature map height * filter width * filfet height * channels
#             ---> For the first layer feature map width and height are the inputs width and height divided by the strides!!
#     - Output Memory:
#         feature maps * feature map width * feature map height * 32 bits * training batch size 
#             ---> Reduce batch size to fir in memory!
# Memory for multiple layers:
#    - During training: The sum of all the layers
#    - During inference: Two consecutive layers

# If you have memory issues:
# 1. Reuduce batch size
# 2. Increase stride
# 3. Remove layers
# 4. Use 16-bit floats
# 5. Distribute across multiple devices

# Pooling layers: shrink the input image to reduce computational load, memory usage and number of parameters
# - Pooling neurons have no weights
# - keras.layers.MaxPool2D(pool_size=(2, 2), strides=None, padding='valid', data_format=None)
# -              AvgPool2D
# - Only takes the maximum (or average, minimum, etc) value of the pooling_size window
# - If stride > 1 reduces the number of parameters. Stride defaults to pool_size
# - Introduces a level of invariance to small translations and some rotational and scale invariance
# - Invariance is desirable for classification but undersirable for semantic segmentation
# - Invariance is desirable if a small change in the inputs should lead to a small change on the outputs
# - MaxPool2D typically has better performance
# - Can also be applied to depth (channels) instead of spatial direction (see page 469)
# - GlobalAvgPool2D: Calculates the average of the entire feature map

# Typical CNN architecture:
# - Convolutions(s) with same number of feature maps --> Pooling --> Convolution(s) --> Pooling --> repeat --> Flatten --> Fully connected layer
# - Image gets smaller (less width and height) and deeper (more feature maps)                                  --> Dense --> Dropout --> Repeat  
# - Avoid large kernels (window sizes)--> use more layers (except in first layer)
# - Number of repetitions is a hyperparameter to tune
# - Double number of filters after each pooling layer
# - Add keras.layers.Dropout(0.5) to reduce overfitting between dense layers

class Sampling(layers.Layer):
    """Uses (z_mean, z_log_var) to sample z, the vector encoding a digit."""

    def call(self, inputs):
        z_mean, z_log_var = inputs
        batch = tf.shape(z_mean)[0]
        dim = tf.shape(z_mean)[1]
        epsilon = tf.keras.backend.random_normal(shape=(batch, dim))
        return z_mean + tf.exp(0.5 * z_log_var) * epsilon


# Expand strides. For example:
# 1. stride = 2 and 3 layers ----------> stride = [2, 2, 2]
# 2. stride = [1,2] and 3 layers ------> stride = [1, 2, 2]
# 3. stride = [1, 2, 3] and 3 layers --> stride = [1, 2, 3]
def get_stride(n, strides):
    if type(strides) != list:
        strides = [strides]
    
    if n <= len(strides)-1:
        return strides[n]
    else:
        return strides[-1]
         

# Multiplies base filter by stride maintain constant number of neurons per layer
def strides2filters(base_filter, strides):
    filters = [base_filter]
    for stride in strides:
        base_filter = base_filter * stride
        filters.append(base_filter)
    return filters[:-1]
    
    
def build_encoder(latent_dim, height, width, channels, n_conv_layers = 2, kernel_size = 3, strides = 2, base_filters = 32):
    encoder_inputs = keras.Input(shape=(height, width, channels))
    label_inputs = keras.layers.Input(shape = [10]) # FIXME: shape may vary
    # Number of filters: 32
    # kernel_size: 3 (integer or list of two integers) -> Width and height of the 2D convolution window or receptive field
    # strides: Shift from one window to the next. The output size is the input size size divided by the stride (rounded up)
    # pading:
    #     - same: Uses zero padding when stride and filter width don't match input width
    #     - valid: Ignores inputs to fit the input width to the stride and filter width
    #x = layers.Conv2D(32, 20, activation="relu", strides=(7,10), padding="same")(encoder_inputs)

    # Expand strides. For example:
    # 1. stride = 2 and 3 layers ----------> stride = [2, 2, 2]
    # 2. stride = [1,2] and 3 layers ------> stride = [1, 2, 2]
    # 3. stride = [1, 2, 3] and 3 layers --> stride = [1, 2, 3]    
    strides = [get_stride(n,strides) for n in range(n_conv_layers) ]
    # Multiplies base filter by stride maintain constant number of neurons per layer
    filters = strides2filters(base_filters, strides)
    
    print('Strides: ', strides)
    print('Filters: ', filters)
    for l in range(n_conv_layers):
        if l == 0:
            x = layers.Conv2D(filters[l], kernel_size, activation="relu", strides=strides[l], padding="same")(encoder_inputs)
        else:
            x = layers.Conv2D(filters[l], kernel_size, activation="relu", strides=strides[l], padding="same")(x)
        # FIXME: Why are there no pooling layers?
        
    x = layers.Flatten()(x)
    concat = layers.Concatenate()([x, label_inputs])
    x = layers.Dense(16, activation="relu")(concat) #(x)
    z_mean = layers.Dense(latent_dim, name="z_mean")(x)
    z_log_var = layers.Dense(latent_dim, name="z_log_var")(x)
    z = Sampling()([z_mean, z_log_var])
    encoder = keras.Model([encoder_inputs, label_inputs], [z_mean, z_log_var, z], name="encoder")
    print(encoder.summary())
    return encoder



def calculate_final_shape(height, strides):
    for s in strides:
        height = int(np.ceil(height / s))
    return height

# Only works for stride 2...
# - Stride must be greater than output padding
def calculate_output_paddings(height, strides):
    print(strides)
    output_paddings = []
    for s in strides:
        output_paddings.append(s - (height % s) - 1)
        height = int(np.ceil(height / s))

    output_paddings.reverse()
    return output_paddings

# Works for stride 3 but may need extra work/testing
# - Probably needs to know the kernel if different from 2!
def _calculate_output_paddings(height, num_conv_layers, stride):
    output_paddings = []
    encoder_heights = []
    decoder_heights = []
    output_paddings = []
    encoder_heights.append(height)
    
    for n in range(num_conv_layers):
        height = int(np.ceil(height / stride))
        encoder_heights.append(height)

    encoder_heights.reverse()

    decoder_heights.append(height)    
    for n in range(num_conv_layers):
        height = int(height * stride)
        padding = height - encoder_heights[n+1]
        print(padding)
        #output_paddings.append(padding + stride - int(stride/2) - 2)
        height -= padding
        decoder_heights.append(height)
        if padding == 0:
            padding = 2
        elif padding == 2:
            padding = 0
        output_paddings.append(padding)

    return output_paddings

def build_decoder(latent_dim, height, width, channels, n_conv_layers = 2, kernel_size = 3, strides = 2, base_filters = 32):
    latent_inputs = keras.Input(shape=(latent_dim,))
    label_inputs = keras.layers.Input(shape = [10]) # FIXME: shape may vary

    # Expand strides. For example:
    # 1. stride = 2 and 3 layers ----------> stride = [2, 2, 2]
    # 2. stride = [1,2] and 3 layers ------> stride = [1, 2, 2]
    # 3. stride = [1, 2, 3] and 3 layers --> stride = [1, 2, 3]
    strides = [ get_stride(n,strides) for n in range(n_conv_layers) ]
    # Multiplies base filter by stride maintain constant number of neurons per layer
    filters = strides2filters(base_filters, strides)
    
    final_height = calculate_final_shape(height, strides)
    final_width = calculate_final_shape(width, strides)
    height_paddings = calculate_output_paddings(height, strides)
    width_paddings = calculate_output_paddings(width, strides)
    final_filters = filters[-1]

    #final_filters = base_filters*np.power(strides, n_conv_layers-1)[-1]
    concat = layers.Concatenate()([latent_inputs, label_inputs])
    x = layers.Dense(final_height * final_width * final_filters, activation="relu")(concat) #(latent_inputs)
    x = layers.Reshape((final_height, final_width, final_filters))(x)

    strides.reverse()
    filters.reverse()
    print('Final height:    ', final_height, flush = True)
    print('Final width:     ', final_width, flush = True)
    print('Strides:         ', strides, flush = True)
    print('Filters:         ', filters, flush = True)
    print('Height paddings: ', height_paddings, flush = True)
    print('Width paddings:  ', width_paddings, flush = True)

    for l in range(n_conv_layers):
        x = layers.Conv2DTranspose(
            filters[l],
            kernel_size,
            activation="relu",
            strides = strides[l],
            padding="same",
            output_padding = [
                height_paddings[l],
                width_paddings[l]
            ]
        )(x)
         
    decoder_outputs = layers.Conv2DTranspose(channels, 3, activation="sigmoid", padding="same")(x)
    decoder = keras.Model([latent_inputs, label_inputs], decoder_outputs, name="decoder")
    print(decoder.summary())
    return decoder

class VAE(keras.Model):
    def __init__(self, encoder, decoder, loss_scale, **kwargs):
        super(VAE, self).__init__(**kwargs)
        self.encoder = encoder
        self.decoder = decoder
        self.total_loss_tracker = keras.metrics.Mean(name="total_loss")
        self.reconstruction_loss_tracker = keras.metrics.Mean(
            name="reconstruction_loss"
        )
        self.kl_loss_tracker = keras.metrics.Mean(name="kl_loss")
        self.loss_scale = loss_scale

    @property
    def metrics(self):
        return [
            self.total_loss_tracker,
            self.reconstruction_loss_tracker,
            self.kl_loss_tracker,
        ]

    def train_step(self, data):
        data = list(data[0])
        X, Y, labels = data[0], data[1], data[2]
        
        # FIXME: Learning rate?
        with tf.GradientTape() as tape:
            z_mean, z_log_var, z = self.encoder([X, labels])
            reconstruction = self.decoder([z, labels])
            reconstruction_loss = tf.reduce_mean(
                tf.reduce_sum(
                    keras.losses.binary_crossentropy(Y, reconstruction), axis=(1, 2)
                )
            )/self.loss_scale
            kl_loss = -0.5 * (1 + z_log_var - tf.square(z_mean) - tf.exp(z_log_var))
            kl_loss = tf.reduce_mean(tf.reduce_sum(kl_loss, axis=1))/self.loss_scale
            total_loss = (reconstruction_loss + kl_loss)
        grads = tape.gradient(total_loss, self.trainable_weights)
        self.optimizer.apply_gradients(zip(grads, self.trainable_weights))
        self.total_loss_tracker.update_state(total_loss)
        self.reconstruction_loss_tracker.update_state(reconstruction_loss)
        self.kl_loss_tracker.update_state(kl_loss)
        return {
            "loss": self.total_loss_tracker.result(),
            "reconstruction_loss": self.reconstruction_loss_tracker.result(),
            "kl_loss": self.kl_loss_tracker.result(),
        }

    # Needed to validate (validation loss) and to evaluate
    def test_step(self, data):
        try:
            X, Y, labels = data
        except:
            data = list(data[0])
            X, Y, labels = data[0], data[1], data[2]    
    
        z_mean, z_log_var, z = self.encoder([X, labels])
        reconstruction = self.decoder([z, labels])
        # FIXME: Normalize loss with the number of features (28*28)
        reconstruction_loss = tf.reduce_mean(
            tf.reduce_sum(
                keras.losses.binary_crossentropy(Y, reconstruction), axis=(1, 2)
            )
        )/self.loss_scale
        kl_loss = -0.5 * (1 + z_log_var - tf.square(z_mean) - tf.exp(z_log_var))
        kl_loss = tf.reduce_mean(tf.reduce_sum(kl_loss, axis=1))/self.loss_scale
        total_loss = (reconstruction_loss + kl_loss)
        #grads = tape.gradient(total_loss, self.trainable_weights)
        #self.optimizer.apply_gradients(zip(grads, self.trainable_weights))
        self.total_loss_tracker.update_state(total_loss)
        self.reconstruction_loss_tracker.update_state(reconstruction_loss)
        self.kl_loss_tracker.update_state(kl_loss)
        return {
            "loss": self.total_loss_tracker.result(),
            "reconstruction_loss": self.reconstruction_loss_tracker.result(),
            "kl_loss": self.kl_loss_tracker.result(),
        }

# Only works if latent_dim = 2
def plot_latent_space(vae, digit_size, channels, n=30, figsize=15, show = False, path = ''):
    # display a n*n 2D manifold of digits
    #digit_size = 28
    scale = 1.0
    figure = np.zeros((digit_size * n, digit_size * n))
    # linearly spaced coordinates corresponding to the 2D plot
    # of digit classes in the latent space
    grid_x = np.linspace(-scale, scale, n)
    grid_y = np.linspace(-scale, scale, n)[::-1]

    for i, yi in enumerate(grid_y):
        for j, xi in enumerate(grid_x):
            z_sample = np.array([[xi, yi]])
            x_decoded = vae.decoder.predict(z_sample)
            digit = x_decoded[0].reshape(digit_size, digit_size, channels)
            figure[
                i * digit_size : (i + 1) * digit_size,
                j * digit_size : (j + 1) * digit_size,
            ] = digit[:,:,0]

    plt.figure(figsize=(figsize, figsize))
    start_range = digit_size // 2
    end_range = n * digit_size + start_range
    pixel_range = np.arange(start_range, end_range, digit_size)
    sample_range_x = np.round(grid_x, 1)
    sample_range_y = np.round(grid_y, 1)
    plt.xticks(pixel_range, sample_range_x)
    plt.yticks(pixel_range, sample_range_y)
    plt.xlabel("z[0]")
    plt.ylabel("z[1]")
    plt.imshow(figure, cmap="Greys_r")
    if show:
        plt.show()
    if path:
        plt.savefig(path)


def plot_images(images, rows, columns, path = '', show = False):
    fig = plt.figure(figsize = (10, 7))
    
    for i, image in enumerate(images):
        fig.add_subplot(rows, columns, i+1)
        try:
            plt.imshow(image, cmap = 'binary')
        except:
            plt.imshow(image.squeeze(), cmap = 'binary')
        plt.axis('off')

    if show:
        plt.show()
    if path:
        plt.savefig(path)


def load_fashion_mnist():
    fashion_mnist = keras.datasets.fashion_mnist
    (X_train, y_train), (X_test, y_test) = fashion_mnist.load_data()
    fashion_mnist = np.concatenate([X_train, X_test], axis=0)
    fashion_mnist = np.expand_dims(fashion_mnist, -1).astype("float32") / 255
    return fashion_mnist

def load_digits_mnist(shuffle = False, shift = False):
    (x_train, y_train), (x_test, y_test) = keras.datasets.mnist.load_data()
    print(y_train)
    X = np.concatenate([x_train, x_test], axis=0)
    y = np.concatenate([y_train, y_test], axis=0)
    if shuffle:
        X_list = []
        Y_list = []
        for i in range(10):
            indices = np.argwhere(y.flatten() == i)
            X_list.append(X[indices][:,0,:,:])
            np.random.shuffle(indices)
            Y_list.append(X[indices][:,0,:,:]) #[:, :, :, 0])

        if shift:
            msg = 'Something is not working right. The sample_input_(X,y).png images are not the same.'
            #raise(Exception(msg))
            Y_list = np.roll(Y_list, 1)
        Y = np.concatenate(Y_list, axis = 0)
        X = np.concatenate(X_list, axis = 0)
        Y = np.expand_dims(Y, -1).astype("float32") / 255
        X = np.expand_dims(X, -1).astype("float32") / 255
        return X, Y
    else:
        X = np.expand_dims(X, -1).astype("float32") / 255
        return X, y

def load_cifar10(class_number = '', channel = ''):
    # https://pgaleone.eu/neural-networks/deep-learning/2016/12/13/convolutional-autoencoders-in-tensorflow/
    (x_train, y_train), (x_test, y_test) = keras.datasets.cifar10.load_data()
    print(x_test.shape)
    print(y_train.shape)
    print(y_train.flatten().shape)
    if class_number:
        indices = np.argwhere(y_train.flatten() == class_number)
        x_train = x_train[indices][:,0,:,:][:, :, :, 0]
        indices = np.argwhere(y_test.flatten() == class_number)
        x_test = x_test[indices][:,0,:,:][:, :, :, 0]

    if channel:
        x_train = x_train[:, :, :, 0]
        x_test = x_test[:, :, :, 0]
    
    print(x_test.shape)
    #print(y_train)
    cifar10 = np.concatenate([x_train, x_test], axis=0)
    #cifar10 = np.expand_dims(cifar10, -1).astype("float32") / 255
    cifar10 = cifar10.astype("float32") / 255
    if len(cifar10.shape) < 4:
        cifar10 = np.expand_dims(cifar10, -1)
    return cifar10


# FIXME: Not ready!
def load_celeba():
    data = tff.simulation.datasets.celeba.load_data()
    print(data.shape)
    return data


def load_pkl(pkl_path):
    with open(pkl_path, "rb") as input_file:
        return pickle.load(input_file)

def load_gefs_open_data_registry(dataset):
    import xarray as xr
    slp_01_ds = xr.open_mfdataset(dataset, engine='pynio')
    print(slp_01_ds)
    # Use MNIST data preproc as template
    many_time_steps = False
    if many_time_steps:
        slp = np.expand_dims(
            np.concatenate(
                [
                    slp_01_ds.PRES_P1_L1_GLL0.values,
                    slp_02_ds.PRES_P1_L1_GLL0.values
                ],
                axis=0
            ),
            -1
        ).astype("float16") / 110000
    else:
        slp = np.expand_dims(
            slp_01_ds.PRES_P1_L1_GLL0.values,
            -1).astype("float32") / 110000

    return slp


if __name__ == '__main__':
    latent_dim = 2
    train = False
    case = 'digits' #-shuffled'
    epochs = 10
    batch_size = 128
    patience = 10
    
    n_conv_layers = 2
    stride = [2, 2] # Use 1 or 2 only!
    kernel_size = 3 # Use only 3!
    base_filters = 32
    
    if case == 'digits':
        data, labels = load_digits_mnist()
        model_dir = './digits'
    elif case == 'digits-shuffled':
        X, Y = load_digits_mnist(shuffle = True, shift = False)
        model_dir = './digits-shuffled'
    elif case == 'fashion':
        data = load_fashion_mnist()
        model_dir = './fashion'
    elif case == 'cifar':
        data = load_cifar10()
        model_dir = './cifar10'
    elif case == 'cifar10-1':
        data = load_cifar10(class_number = 1, channel = 0)
        model_dir = './cifar10-1'
        
    os.makedirs(model_dir, exist_ok = True)

    # One Hot Encode integer labels from 0 to 9
    labels = np.squeeze(np.eye(10)[labels.reshape(-1)])

    # X in general is the same as Y. The only situation in which they are different is when the digits are shuffled
    # If the digits are shuffled the digit will be the same (0,1,2...) but the image of the digit will be different
    if case != 'digits-shuffled':
        print(data.shape)
        X_train, X_test, labels_train, labels_test = train_test_split(data, labels)
        X_train, X_valid, labels_train, labels_valid = train_test_split(X_train, labels_train)
        Y_train = X_train
        Y_valid = X_valid
        Y_test = X_test
    else:
        X_train, X_test, Y_train, Y_test, labels_train, labels_test = train_test_split(X, Y, labels)
        X_train, X_valid, Y_train, Y_valid, labels_train, labels_valid = train_test_split(X_train, Y_train, labels_train)

    print(X_train.shape, Y_train.shape, labels_train.shape, X_valid.shape, Y_valid.shape, labels_valid.shape, X_test.shape, Y_test.shape, labels_test.shape)

    num_samples, height, width, channels = X_train.shape
    # Plot some inputs
    rows = 3
    columns = 4
    sample_input_images = X_train[0:rows*columns]
    sample_labels = labels_train[0:rows*columns]
    print(labels_train[0:rows*columns])
    plot_images(X_train[0:rows*columns], rows, columns,  path = os.path.join(model_dir, 'sample_input_X.png'))
    plot_images(Y_train[0:rows*columns], rows, columns,  path = os.path.join(model_dir, 'sample_input_Y.png'))
    
    # More conv layers reduces the total parameters at first but then it does not!
    encoder = build_encoder(latent_dim, height, width, channels, n_conv_layers, kernel_size, stride, base_filters)
    decoder = build_decoder(latent_dim, height, width, channels, n_conv_layers, kernel_size, stride, base_filters)
    vae = VAE(encoder, decoder, height*width)
    
    vae.compile(optimizer = 'rmsprop')
    #quit()
    if train:
        early_stopping_cb = keras.callbacks.EarlyStopping(patience = patience, restore_best_weights = True)
        history = vae.fit(
            (X_train, Y_train, labels_train), epochs = epochs, batch_size = batch_size,
            callbacks = [early_stopping_cb],
            validation_data = (X_valid, Y_valid, labels_valid)
        )
        vae.save_weights(os.path.join(model_dir, 'vae'))
        hist_pd = pd.DataFrame(history.history)
        hist_pd.to_csv(os.path.join(model_dir, 'history.csv'), index = False)
        test_loss = vae.evaluate((X_test, Y_test, labels_test))
        test_loss = dict(zip(["loss", "reconstruction_loss", "kl_loss"], test_loss))
        print('Test loss:')
        print(test_loss)
        with open(os.path.join(model_dir, 'test_loss.json'), 'w') as json_file:
            json.dump(test_loss, json_file, indent = 4)
            
    else:
        vae.load_weights(os.path.join(model_dir, 'vae'))

            
    # Generating new images
    # - Verify that the images match the labels!
    codings = tf.random.normal(shape = [12, latent_dim])
    labels_ = labels_train[0:12]
    print(labels_)
    images = vae.decoder([codings, labels_]).numpy()
    plot_images(images, 3, 4, path = os.path.join(model_dir, 'random_generated.png'))

    # Generating new images for each digit:
    codings = tf.random.normal(shape = [10, latent_dim])
    # Copy 10 times the previous array
    codings = np.tile(codings, (10,1))
    labels_ = np.concatenate([ np.full(10,i) for i in range(10) ])
    # One Hot Encode integer labels from 0 to 9
    labels_ = np.squeeze(np.eye(10)[labels_.reshape(-1)])
    images = vae.decoder([codings, labels_]).numpy()
    plot_images(images, 10, 10, path = os.path.join(model_dir, '10x10_generated.png'))    
    
    # Encode / decode images
    # FIXME: Maybe add a predict method?
    # sample_output_images = vae.predict(sample_input_images)
    z_mean, z_log_var, z = vae.encoder([sample_input_images, sample_labels])
    sample_output_images = vae.decoder([z, sample_labels])
    plot_images(sample_output_images, rows, columns,  path = os.path.join(model_dir, 'sample_output.png'))

    quit() # Generalize for conditional VAE
    # Semantic interpolation
    codings_grid = tf.reshape(codings, [1, 3, 4, latent_dim])
    larger_grid = tf.image.resize(codings_grid, size = [5, 7])
    interpolated_codings = tf.reshape(larger_grid, [-1, latent_dim])

    images = vae.decoder(interpolated_codings).numpy()
    plot_images(images, 5, 7, path = os.path.join(model_dir, 'interpolated.png'))

    if False: # FIXME: Only works without the conditional part #latent_dim == 2:
        # Only works if:
        if height == width:
            plot_latent_space(vae, height, channels, path = os.path.join(model_dir, 'latent_space.png'))    
    
