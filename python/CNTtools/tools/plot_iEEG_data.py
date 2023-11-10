import matplotlib.pyplot as plt
import matplotlib as mpl
import numpy as np
from beartype import beartype


@beartype
def plot_ieeg_data(data: np.ndarray, chs, t):
    """
    Plot iEEG data for multiple channels over time.

    Parameters:
    - data (np.ndarray): 2D array representing iEEG data. Each column corresponds to a channel, and each row corresponds to a time point.
    - chs (list): List of channel names corresponding to the columns in the data array.
    - t (list): linspace of time to plot

    Returns:
    - fig (matplotlib.figure.Figure): The generated matplotlib Figure object.

    Example:
    data = np.random.rand(100, 5)  # Replace with your actual iEEG data
    chs = ['Channel 1', 'Channel 2', 'Channel 3', 'Channel 4', 'Channel 5']  # Replace with actual channel names
    t = [0, 10]  # Replace with your actual time points

    fig = plot_iEEG_data(data, chs, t)
    plt.show()
    """

    # offset = 0
    nchan = data.shape[1]
    medians = np.nanmedian(data, axis=0)
    up = np.nanmax(data, axis=0) - medians
    down = medians - np.nanmin(data, axis=0)
    percentile = 80
    spacing = 2 * np.percentile(np.concatenate([up, down]), percentile)
    ticks = np.arange(0, spacing * (nchan - 1) + 1, spacing)
    fig, ax = plt.subplots(figsize=(15, 15))
    mpl.rcParams["axes.spines.right"] = False
    mpl.rcParams["axes.spines.top"] = False
    mpl.rcParams["axes.spines.left"] = True
    mpl.rcParams["font.size"] = 9

    plt.plot(t, data - medians + ticks, "k")
    plt.yticks(ticks, chs)
    ax.spines["left"].set_visible(True)
    plt.gca().set_xlim(t[0], plt.gca().get_xlim()[1])
    plt.xlabel("Time")
    plt.ylabel("Channels")
    plt.grid(axis="x")
    # pass a plt.xlim that focuses around the center of the spike
    plt.show()

    return fig
