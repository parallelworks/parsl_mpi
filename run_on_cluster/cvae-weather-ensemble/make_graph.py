import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

import os

history_files = [f for f in os.listdir('./model_dir/') if 'history' in f]
all_history = pd.DataFrame()

for history in history_files:
    history_df = pd.read_csv('./model_dir/' + history)
    all_history = pd.concat([all_history, history_df], ignore_index = True)
    

plt.ylim(365, 400)
plt.plot(all_history['loss'])
plt.show()
plt.savefig('plot_of_loss.png') 