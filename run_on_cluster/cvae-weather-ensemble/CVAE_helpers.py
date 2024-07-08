import os, json

import papermill as pm
import numpy as np
import pandas as pd

import matplotlib.pyplot as plt
import tensorflow as tf
import netCDF4
import cartopy

from tensorflow import keras
from keras import layers
from sklearn.model_selection import train_test_split
    
class Sampling(layers.Layer):
    """Uses (z_mean, z_log_var) to sample z, the vector encoding a digit."""

    def call(self, inputs):
        z_mean, z_log_var = inputs
        batch = tf.shape(z_mean)[0]
        dim = tf.shape(z_mean)[1]
        epsilon = tf.keras.backend.random_normal(shape=(batch, dim))
        return z_mean + tf.exp(0.5 * z_log_var) * epsilon

def build_encoder(latent_dim):
    encoder_inputs = keras.Input(shape=(721, 1440, 1))
    
    x = layers.Conv2D(32, 11, activation = "relu", strides = [9, 10], padding = "valid")(encoder_inputs)
    x = layers.Conv2D(64, [5,9], activation = "relu", strides = [5, 9], padding = "valid")(x)
    x = layers.Flatten()(x)
    x = layers.Dense(16, activation="relu")(x)
    
    z_mean = layers.Dense(latent_dim, name="z_mean")(x)
    z_log_var = layers.Dense(latent_dim, name="z_log_var")(x)
    z = Sampling()([z_mean, z_log_var])
    
    encoder = keras.Model(encoder_inputs, [z_mean, z_log_var, z], name = "encoder")
    
    print(encoder.summary())
    return encoder

def build_decoder(latent_dim):
    latent_inputs = keras.Input(shape=(latent_dim,))
    x = layers.Dense(15 * 15 * 64, activation="relu")(latent_inputs)
    x = layers.Reshape((15, 15, 64))(x)
    # FIXME - there is something wrong here, but at least there is a pattern.
    # Using output_padding as a fudge factor -> it may be that there is exactly
    # one "missing" filter stamp/convolution because for both Conv2DTranspose
    # operations, output_padding is set to maximum it could be in both dims
    # (i.e. exactly one less than the stride of each filter).
    x = layers.Conv2DTranspose(64, [5, 9], activation = "relu", strides = [5,9], padding = "valid", output_padding = [4, 8])(x)
    x = layers.Conv2DTranspose(32, 11, activation = "relu", strides = [9,10], padding = "valid", output_padding = [8, 9])(x)
    decoder_outputs = layers.Conv2DTranspose(1, 3, activation = "sigmoid", padding = "same")(x)
    decoder = keras.Model(latent_inputs, decoder_outputs, name = "decoder")
    
    print(decoder.summary())
    return decoder

class VAE(keras.Model):
    def __init__(self, encoder, decoder, **kwargs):
        super(VAE, self).__init__(**kwargs)
        self.encoder = encoder
        self.decoder = decoder
        self.total_loss_tracker = keras.metrics.Mean(name = "total_loss")
        self.reconstruction_loss_tracker = keras.metrics.Mean(name = "reconstruction_loss")
        self.kl_loss_tracker = keras.metrics.Mean(name = "kl_loss")

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
            # FIXME: Normalize loss with the number of features (28 * 28)
            n_features = 28 * 28
            reconstruction_loss = tf.reduce_mean(
                tf.reduce_sum(
                    keras.losses.binary_crossentropy(data, reconstruction), axis = (1, 2)
                )
            ) / n_features
            kl_loss = -0.5 * (1 + z_log_var - tf.square(z_mean) - tf.exp(z_log_var))
            kl_loss = tf.reduce_mean(tf.reduce_sum(kl_loss, axis = 1)) / n_features
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
        # FIXME: Normalize loss with the number of features (28 * 28)
        n_features = 28 * 28
        reconstruction_loss = tf.reduce_mean(
            tf.reduce_sum(
                keras.losses.binary_crossentropy(data, reconstruction), axis = (1, 2)
            )
        ) / n_features
        kl_loss = -0.5 * (1 + z_log_var - tf.square(z_mean) - tf.exp(z_log_var))
        kl_loss = tf.reduce_mean(tf.reduce_sum(kl_loss, axis = 1)) / n_features
        total_loss = (reconstruction_loss + kl_loss)
        # grads = tape.gradient(total_loss, self.trainable_weights)
        # self.optimizer.apply_gradients(zip(grads, self.trainable_weights))
        self.total_loss_tracker.update_state(total_loss)
        self.reconstruction_loss_tracker.update_state(reconstruction_loss)
        self.kl_loss_tracker.update_state(kl_loss)
        
        return {
            "loss": self.total_loss_tracker.result(),
            "reconstruction_loss": self.reconstruction_loss_tracker.result(),
            "kl_loss": self.kl_loss_tracker.result(),
        }

latent_dim = 2
train = True
model_dir = './model_dir'
    
def train_model(X_train, X_test, X_valid, date):
    early_stopping_cb = keras.callbacks.EarlyStopping(patience = 5, restore_best_weights = True) # stops training early if the validation loss does not improve

    if os.path.exists(os.path.join(model_dir, 'vae.weights.h5')): # if the model has already been trained at least once, load that model
        vae.load_weights(os.path.join(model_dir, 'vae.weights.h5'))
        reloaded = tf.saved_model.load(model_dir)

    history = vae.fit(
        X_train, epochs = 50, batch_size = 40,
        callbacks = [early_stopping_cb],
        validation_data = (X_valid,)
    )

    vae.save_weights(os.path.join(model_dir, 'vae.weights.h5')) # save model weights after training
    tf.saved_model.save(vae, model_dir)

    hist_pd = pd.DataFrame(history.history)
    hist_pd.to_csv(os.path.join(model_dir, f'history_{date}.csv'), index = False)

    test_loss = vae.evaluate(X_test)
    test_loss = dict(zip(["loss", "reconstruction_loss", "kl_loss"], test_loss))

    print('Test loss:', test_loss)

    with open(os.path.join(model_dir, f'test_loss_{date}.json'), 'w') as json_file:
        json.dump(test_loss, json_file, indent = 4)

data_prefix = "./gefs_data"
data_dir = data_prefix + '/' + 'converted/'
        
# used MNIST data preproc as template for this definition
def load_data(): 
    files = os.listdir(data_dir)
    files = [f for f in files if '.nc' in f]
    
    all_data = np.expand_dims(
        np.concatenate(
            [netCDF4.Dataset(data_dir + converted_file)['msl'][:] for converted_file in files]
        ),
        -1
    ).astype("float32") / 110000
    return all_data
        
def run_train(num_files, date):
    slp = load_data() # load data
    print("shape:", np.shape(slp)) # verify data shape
    
    # split the data - y values are throw away
    X_train, X_test, y_train, y_test = train_test_split(slp[0:(num_files * 80 - 1), :, :, :], np.arange(0, num_files * 80 - 1), test_size = 0.2, random_state = 1)
    X_train, X_valid, y_train, y_valid = train_test_split(X_train, y_train, test_size = 0.25, random_state = 1) # 0.25 x 0.8 = 0.2

    train_model(X_train, X_test, X_valid, date)
    remove_data()