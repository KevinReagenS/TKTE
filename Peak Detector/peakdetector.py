import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import find_peaks

# Load the ECG data from the file content
ecg_data = []
with open("ecg_data_amp.txt", "r") as f:
    for line in f:
        ecg_data.append(float(line.strip()))

# Convert to numpy array
ecg_data = np.array(ecg_data)

# Plot the ECG data
plt.figure(figsize=(15, 6))
plt.plot(ecg_data)
plt.title('ECG Signal')
plt.xlabel('Sample')
plt.ylabel('Amplitude')

# Find R-peaks (positive peaks in the ECG signal)
# Based on visual inspection of the data, we need a proper threshold
height_threshold = 0.5  # Will detect major R-peaks
r_peaks, _ = find_peaks(ecg_data, height=height_threshold, distance=100)

# Mark the peaks on the plot
plt.plot(r_peaks, ecg_data[r_peaks], 'ro', label='R-peaks')
plt.legend()

# Print the peaks and their values
print(f"Number of R-peaks detected: {len(r_peaks)}")
print("\nR-peak locations and values:")
for i, peak in enumerate(r_peaks):
    print(f"Peak {i+1}: Sample {peak}, Value: {ecg_data[peak]:.3f}")

# Let's also try a lower threshold to see if we capture all the peaks
plt.figure(figsize=(15, 6))
plt.plot(ecg_data)
plt.title('ECG Signal with Lower Threshold for Peak Detection')
plt.xlabel('Sample')
plt.ylabel('Amplitude')

# Fine-tuning our approach for this specific ECG data
# After analyzing the data, let's identify R-peaks more precisely
r_peaks_final = []
peak_values = []

# We'll use a local maximum approach with proper windowing
window_size = 50  # For local max detection
min_peak_height = 0.7  # Minimum R-peak height

# Loop through the data to find clear R-peaks in ECG waveforms
for i in range(len(ecg_data)):
    # Skip beginning and end of data where we can't center a window
    if i < window_size//2 or i >= len(ecg_data) - window_size//2:
        continue
    
    # Get the window around the current point
    window = ecg_data[i-window_size//2:i+window_size//2]
    
    # Check if current point is the max in the window and above threshold
    if ecg_data[i] == max(window) and ecg_data[i] > min_peak_height:
        r_peaks_final.append(i)
        peak_values.append(ecg_data[i])

plt.plot(r_peaks_final, ecg_data[r_peaks_final], 'go', label='Final R-Peaks')
plt.legend()

print(f"\nFinal number of R-peaks detected: {len(r_peaks_final)}")
print("\nR-peak locations and values:")
for i, peak in enumerate(r_peaks_final):
    print(f"Peak {i+1}: Sample {peak}, Value: {ecg_data[peak]:.3f}")