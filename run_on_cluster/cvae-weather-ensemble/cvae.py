# https://keras.io/examples/generative/vae/
import os, json
import pickle
import glob
import numpy as np
import pandas as pd

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

from sklearn.model_selection import train_test_split

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


def build_encoder(latent_dim, height, width, channels, n_conv_layers = 2, kernel_size = 3, strides = 2, base_filters = 32):
    # Number of filters: 32
    # kernel_size: 3 (integer or list of two integers) -> Width and height of the 2D convolution window or receptive field
    # strides: Shift from one window to the next. The output size is the input size size divided by the stride (rounded up)
    # pading:
    #     - same: Uses zero padding when stride and filter width don't match input width
    #     - valid: Ignores inputs to fit the input width to the stride and filter width
    
    # x = layers.Conv2D(32, 20, activation="relu", strides=(7,10), padding="same")(encoder_inputs)

    encoder_inputs = keras.Input(shape=(height, width, channels))
    
    for l in range(n_conv_layers):
        n_filters = int(base_filters * np.power(2, l))
        
        if l == 0:
            x = layers.Conv2D(n_filters, kernel_size, activation="relu", strides=strides, padding="same")(encoder_inputs)
        else:
            x = layers.Conv2D(n_filters, kernel_size, activation="relu", strides=strides, padding="same")(x)
        # FIXME: Why are there no pooling layers?

    x = layers.Flatten()(x)
    x = layers.Dense(8, activation="relu")(x)
    
    z_mean = layers.Dense(latent_dim, name="z_mean")(x)
    z_log_var = layers.Dense(latent_dim, name="z_log_var")(x)
    z = Sampling()([z_mean, z_log_var])
    
    encoder = keras.Model(encoder_inputs, [z_mean, z_log_var, z], name="encoder")
    
    print(encoder.summary())
    return encoder

def calculate_final_shape(height, num_conv_2d_layers, stride):
    for n in range(num_conv_2d_layers):
        height = int(np.ceil(height / stride))
    return height

# Only works for stride 2...
def calculate_output_paddings(height, num_conv_2d_layers, stride):
    output_paddings = []
    for n in range(num_conv_2d_layers):
        output_paddings.append(stride - (height % stride) - 1)
        height = int(np.ceil(height / stride))

    output_paddings.reverse()
    return output_paddings

# Works for stride 3 but may need extra work/testing
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

    # Adjusting for the first and last layers!
    # height = int(height/7)
    # width = int(width/10)

    final_height = calculate_final_shape(height, n_conv_layers, strides)
    final_width = calculate_final_shape(width, n_conv_layers, strides)
    height_paddings = calculate_output_paddings(height, n_conv_layers, strides)
    width_paddings = calculate_output_paddings(width, n_conv_layers, strides)
    final_filters = base_filters * np.power(2, n_conv_layers - 1)

    x = layers.Dense(final_height * final_width * final_filters, activation="relu")(latent_inputs)
    x = layers.Reshape((final_height, final_width, final_filters))(x)

    for l in range(n_conv_layers):
        filters = base_filters * np.power(2, n_conv_layers - l - 1)
        
        x = layers.Conv2DTranspose(filters, kernel_size, activation="relu", strides=strides, padding="same", output_padding=[height_paddings[l], width_paddings[l]])(x)

    # x = layers.Conv2DTranspose(32, 10, activation="relu", strides=(7,10), padding="same")(x)
    decoder_outputs = layers.Conv2DTranspose(channels, 3, activation="sigmoid", padding="same")(x)
    decoder = keras.Model(latent_inputs, decoder_outputs, name="decoder")
    
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

        with tf.GradientTape() as tape:
            z_mean, z_log_var, z = self.encoder(data)
            reconstruction = self.decoder(z)
            reconstruction_loss = tf.reduce_mean(
                tf.reduce_sum(
                    keras.losses.binary_crossentropy(data, reconstruction), axis=(1, 2)
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
        if type(data) == tuple:
            data, _ = data

        z_mean, z_log_var, z = self.encoder(data)
        reconstruction = self.decoder(z)
        # FIXME: Normalize loss with the number of features (28*28)
        reconstruction_loss = tf.reduce_mean(
            tf.reduce_sum(
                keras.losses.binary_crossentropy(data, reconstruction), axis=(1, 2)
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

def load_cifar10():
    # https://pgaleone.eu/neural-networks/deep-learning/2016/12/13/convolutional-autoencoders-in-tensorflow/
    (x_train, y_train), (x_test, y_test) = keras.datasets.cifar10.load_data()
    cifar10 = np.concatenate([x_train, x_test], axis=0)
    #cifar10 = np.expand_dims(cifar10, -1).astype("float32") / 255
    cifar10 = cifar10.astype("float16") / 255
    return cifar10

def load_many_grib(
        grib_pattern,
        data_type=np.float16,
        slow_summary=False,
        min_max_norm=True):
    
    import pygrib

    # Similar to load_many_pkl but loads several files
    # that pattern match the submitted string. Include
    # asterix, question mark, etc. in the _pattern.
    filename_list = glob.glob(grib_pattern)

    # For data access, using examples at https://jswhit.github.io/pygrib/api.html
    # as a template.  Set flag and counter.
    tt = 0
    ff = 1
    first_time_step_flag = True
    for filename in filename_list:
        print('Loading '+filename+' file '+str(ff)+' of '+str(len(filename_list)))
        data = pygrib.open(filename).select(name='Mean sea level pressure')
        
        # Advantage to directly grabbing from grib is that we can
        # check for units with timestep['units'] and dimensions
        # to preallocate memory.  To keep things fast,
        # assume same units throughout data set and MSL is in Pa.
        # Convert to hPa by divide by 100 -> used in weather maps and
        # fits in float16/int16 range of +- 32767.
        # We also know in advance the
        # size of the data we are about to load so we can preallocate
        # a block of data.  See https://stackoverflow.com/questions/13215525/how-to-extend-an-array-in-place-in-numpy
        # for why we cannot in general extend array size on the fly.
        # This is where FORTRAN and C would excel. Get data size for
        # first file only.
        if first_time_step_flag:
            ntime = 0
            for timestep in data:
                ntime = ntime + 1
            nfile = len(filename_list)
            print("Found "+str(nfile)+" files and "+str(ntime)+" time steps.")
            
            batch = nfile*ntime
            height = data[1]['Nj']
            width = data[1]['Ni']
            channel = 1
            
            print("Allocating for "+str(batch)+" x "+str(height)+" x "+str(width)+" x "+str(channel)+" shape")
            output = np.zeros([batch,height,width,1],dtype=data_type)

            print("Allocating mean, min, and max storage")
            avgs = np.zeros([batch,1],dtype=data_type)
            maxs = np.zeros([batch,1],dtype=data_type)
            mins = np.zeros([batch,1],dtype=data_type)
            stds = np.zeros([batch,1],dtype=data_type)
            
            # Set flag to avoid repeating.
            first_time_step_flag = False

        for timestep in data:
            # First time step creates the array
            # Add batch and channel dimensions to first and last axes.
            # WORKING HERE: Automatic type conversion to ints is truncation!!!
            #print('Loading timestep '+str(tt)+' of '+str(batch))
            output[tt,:,:,0] = timestep.values/100
            avgs[tt,0] = timestep['average']/100
            stds[tt,0] = timestep['standardDeviation']/100
            mins[tt,0] = timestep['minimum']/100
            maxs[tt,0] = timestep['maximum']/100
            tt = tt + 1

        # Move to the next file
        ff = ff + 1
        
    # Normalize and spit out sanity check statistics at the very end.
    # Crosscheck with ['average'] and ['standardDeviation']
    # data attributes.
    min_out = np.min(mins)
    max_out = np.max(maxs)
    del_out = max_out - min_out
    
    print('Summary: ------------------')
    # Taking mean, min, max over all data is time consuming.
    # Only included here for cross checking.
    if slow_summary:
        print('np.mean(output) = '+str(np.mean(output)))
        
    print('np.mean(avgs)   = '+str(np.mean(avgs)))

    if slow_summary:
        print('np.min(output)  = '+str(np.min(output)))
        
    print('np.min(mins)    = '+str(min_out))

    if slow_summary:
        print('np.max(output)  = '+str(np.max(output)))
        
    print('np.max(maxs)    = '+str(max_out))
    # Computing np.std on output takes up huge amount of RAM.
    # Coalescing different files' standard deviations is complex,
    # these numbers are just for reference and are not to be
    # used in production.  Since +/- 3std should encompass most
    # of the data, max-min ~ 6*mean(stds)
    # Actually, max-min > 6*mean(std) because a true combined std
    # has an additional term that takes into account the differences
    # in the means of the two samples that are being combined.
    #print('np.std(output)  = '+str(np.std(output)))
    print('np.mean(stds)   = '+str(np.mean(stds)))

    # Use min-max scaler approach to ensure that all values are
    # always between 0 and 1.  If we use std as a normalizer, there
    # could be values outside +/- 1 (and even outside +/- 3).
    # Direct approach makes copy of data -> large RAM usage
    #output = (output - np.min(mins))/(np.max(maxs) - np.min(mins))
    # Replace with inplace operations.  See https://stackoverflow.com/questions/10149416/numpy-modify-array-in-place for even more general code.
    # Allow for NOT normalizing in case data is loaded piece-wise in __main__
    # so normalization can be done over multiple loads.
    if min_max_norm:
        output -= min_out
        output /= del_out

        if slow_summary:
            print('After normalization:')
            print('np.mean(output) = '+str(np.mean(output)))
            print('np.min(output)  = '+str(np.min(output)))
            print('np.max(output)  = '+str(np.max(output)))

    return output, min_out, max_out

def load_gefs_open_data_registry(dataset):
    import xarray as xr
    slp_01_ds = xr.open_mfdataset(dataset, engine='cfgrib')
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
            -1).astype("float16") / 110000
    return slp




# Maybe reconstruction loss is big because it is not normalized?
if __name__ == '__main__':
    latent_dim = 3
    train = True
    model_dir = './digits'
    model_dir = './cifar'
    model_dir = './gefs'
    n_conv_layers = 4
    stride = 2
    kernel_size = 3
    os.makedirs(model_dir, exist_ok = True)

    #data = load_fashion_mnist()
    #data = load_digits_mnist()
    #data = load_cifar10()

    # Batch size is too small!
    #data = load_gefs_open_data_registry("/home/jovyan/work/pres_sfc_2019010100*")
    #data = load_pkl('pres_sfc_2019100100_c00.nc.pkl')
    #data = load_many_pkl('pres_msl_201*00_c00.nc.pkl')

    # WORKS FINE, but use selective loading, below, to avoid
    # making data copies.
    #data, data_min, data_max = load_many_grib('./gefs_data/pres_msl_*.grib2')
    #data = load_pkl('gefs.pkl')

    # FIXME: Width and height need to be divisible by number of layers!
    #
    #print('Input summary:')
    #print(data.shape)

    # When using a large data set,
    # - mean takes a long time,
    # - std takes more than 2x RAM
    # - train_test_split makes RAM intensive data copies.
    # Instead, selectively load different data sets.
    #print('Mean: '+str(np.mean(data)))
    # More than doubles RAM usage to find std.
    #print('Std:  '+str(np.std(data)))
    #X_train, X_test = train_test_split(data)
    #X_train, X_valid = train_test_split(X_train)

    # Load and then normalize all data based on
    # same absolute min/max values.  It looks like
    # if data is not in np.float32, it will be internally
    # converted to np.float32 in vae.fit, so there may be no
    # way to cut memory useage there.
    X_train, train_min, train_max = load_many_grib(
        './gefs_data/pres_msl_201[78]*.grib2',
        data_type=np.float32,
        min_max_norm=False)
    X_test, test_min, test_max = load_many_grib(
        './gefs_data/pres_msl_20190[13579]*.grib2',
        data_type=np.float32,
        min_max_norm=False)
    X_valid, valid_min, valid_max = load_many_grib(
        './gefs_data/pres_msl_20190[2468]*.grib2',
        data_type=np.float32,
        min_max_norm=False)

    all_min = np.min([train_min,test_min,valid_min])
    all_max = np.max([train_max,test_max,valid_max])
    all_del = all_max - all_min

    print('Normalize X_train...')
    X_train -= all_min
    X_train /= all_del

    print('Normalize X_test...')
    X_test -= all_min
    X_test /= all_del

    print('Normalize X_valid...')
    X_valid -= all_min
    X_valid /= all_del
    
    print('Testing shape')
    print(np.shape(X_test))

    print('Training shape')
    print(np.shape(X_train))

    print('Validaiton shape')
    print(np.shape(X_valid))

    batch_size, height, width, channels = X_train.shape
    # Plot some inputs
    rows = 3
    columns = 4
    sample_input_images = X_train[0:rows*columns]
    #plot_images(sample_input_images, rows, columns,  path = os.path.join(model_dir, 'sample_input.png'))

    # More conv layers reduces the total parameters at first but then it does not!
    encoder = build_encoder(latent_dim, height, width, channels, n_conv_layers, kernel_size, stride, base_filters = 16)
    decoder = build_decoder(latent_dim, height, width, channels, n_conv_layers, kernel_size, stride, base_filters = 16)
    vae = VAE(encoder, decoder, height*width)
    #vae.compile(optimizer=keras.optimizers.Adam())
    vae.compile(optimizer = 'rmsprop')
    if train:
        early_stopping_cb = keras.callbacks.EarlyStopping(patience = 7, restore_best_weights = True)
        history = vae.fit(
            X_train, epochs = 5, batch_size = 8,
            callbacks = [early_stopping_cb],
            validation_data = (X_valid,)
        )
        vae.save_weights(os.path.join(model_dir, 'vae'))
        hist_pd = pd.DataFrame(history.history)
        hist_pd.to_csv(os.path.join(model_dir, 'history.csv'), index = False)
        test_loss = vae.evaluate(X_test)
        test_loss = dict(zip(["loss", "reconstruction_loss", "kl_loss"], test_loss))
        print('Test loss:')
        print(test_loss)
        with open(os.path.join(model_dir, 'test_loss.json'), 'w') as json_file:
            json.dump(test_loss, json_file, indent = 4)

    else:
        vae.load_weights(os.path.join(model_dir, 'vae'))

    if latent_dim == 2:
        # Only works if:
        if height == width:
            #plot_latent_space(vae, height, channels, path = os.path.join(model_dir, 'latent_space.png'))
            print('Not plotting anything.')

    # Generating new images
    codings = tf.random.normal(shape = [12, latent_dim])
    images = vae.decoder(codings).numpy()
    #plot_images(images, 3, 4, path = os.path.join(model_dir, 'generated.png'))

    # Semantic interpolation
    codings_grid = tf.reshape(codings, [1, 3, 4, latent_dim])
    larger_grid = tf.image.resize(codings_grid, size = [5, 7])
    interpolated_codings = tf.reshape(larger_grid, [-1, latent_dim])
    images = vae.decoder(interpolated_codings).numpy()
    #plot_images(images, 5, 7, path = os.path.join(model_dir, 'interpolated.png'))

    # Encode / decode images
    # FIXME: Maybe add a predict method?
    # sample_output_images = vae.predict(sample_input_images)
    z_mean, z_log_var, z = vae.encoder(sample_input_images)
    sample_output_images = vae.decoder(z)
    #plot_images(sample_output_images, rows, columns,  path = os.path.join(model_dir, 'sample_output.png'))


