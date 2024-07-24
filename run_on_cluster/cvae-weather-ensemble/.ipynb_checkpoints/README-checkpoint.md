# CVAE Weather Ensemble Model

This is the CVAE Weather Ensemble Model repository. The model leverages the power of Conditional Variational Autoencoders (CVAE) to provide an ensemble training system for weather predictions while also answering the big data problem. Its capability for online training allows for continuous learning from new data streams without compromising performance. That is, data used to train the model is processed in small batches, the model being retrained with each new batch. 

## Key Features

* **Conditional Variational Autoencoder (CVAE):** Utilizes CVAE with Conv2d networks to model complex dependencies in weather data, enabling accurate probabilistic forecasts.
* **Online Training:** Implements a dynamic training approach that can adapt to real-time incoming data, ensuring up-to-date forecasts.
* **Data Version Control (DVC):** Manages datasets and model versions effectively with DVC, facilitating reproducibility and collaboration.

## Getting Started

To get started with the CVAE Weather Ensemble Model, follow the instructions below to set up your environment and start making predictions.

1. Open the `cvae_runner_and_example` notebook


*This is based on an example from Keras.io by fchollet*