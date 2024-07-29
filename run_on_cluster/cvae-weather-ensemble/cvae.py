# https://keras.io/examples/generative/vae/
import os, json
# import pickle
import glob

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

import tensorflow as tf
from tf import keras
from keras import layers

from sklearn.model_selection import train_test_split



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


