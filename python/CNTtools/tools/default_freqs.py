import numpy as np

"""
Returns a set of canonical frequency ranges.

Returns:
-------
freqs : ndarray
    A matrix where each row represents a frequency range. The first
    column is the lower bound, and the second column is the upper
    bound of the frequency range. Sequence: delta, theta, alpha, beta,
    gamma, ripple, broadband.
"""
freqs = np.array([[0.5, 4], [4, 8], [8, 12], [12, 30], [30, 80], [80, 250], [0.5, 250]])
