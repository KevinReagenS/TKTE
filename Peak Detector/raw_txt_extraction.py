import wfdb
import matplotlib.pyplot as plt
import numpy as np

def decimal_to_custom_16bit(decimal_num):
    """
    Konversi angka desimal ke format kustom 16-bit: 1 bit sign, 4 bit integer, 11 bit mantissa.
    
    Format:
    - Bit 15: Sign (0 = positif, 1 = negatif)
    - Bit 14-11: Integer (4 bit unsigned)
    - Bit 10-0: Mantissa (11 bit fraksi)
    
    Rentang nilai yang dapat direpresentasikan:
    - Maksimum: +15.99951171875  (0b0111111111111111)
    - Minimum: -15.99951171875   (0b1111111111111111)
    
    Parameters:
        decimal_num (float): Angka desimal yang akan dikonversi.
    
    Returns:
        str: Representasi biner 16-bit (format: sign + integer + mantissa).
    """
    # Handle sign
    sign_bit = '1' if decimal_num < 0 else '0'
    abs_num = abs(decimal_num)
    
    # Pisahkan bagian integer dan fraksi
    int_part = int(abs_num)
    frac_part = abs_num - int_part
    
    # Pastikan bagian integer tidak melebihi 4 bit (0-15)
    if int_part > 15:
        raise ValueError("Bagian integer tidak boleh lebih dari 15 (4 bit).")
    
    # Konversi bagian integer ke 4-bit biner
    int_bits = bin(int_part)[2:].zfill(4)
    
    # Konversi bagian fraksi ke 11-bit biner
    frac_bits = []
    remaining = frac_part
    for _ in range(11):
        remaining *= 2
        bit = int(remaining)
        frac_bits.append(str(bit))
        remaining -= bit
    frac_bits = ''.join(frac_bits)
    
    # Gabungkan semua bagian
    custom_16bit = sign_bit + int_bits + frac_bits
    
    return custom_16bit

# Contoh penggunaan
decimal_num = -12.75  # Contoh angka negatif dengan integer dan fraksi
binary_custom = decimal_to_custom_16bit(decimal_num)

# Path record
record_name = './TKTE/mit-bih-arrhythmia-database-1.0.0/101'
record = wfdb.rdrecord(record_name)

sampling_rate = int(record.fs)
start_sample = 5 * sampling_rate
end_sample = 10 * sampling_rate

# Ambil index dan amplitudo
sample_indices = np.arange(start_sample, end_sample)
amplitudes = record.p_signal[start_sample:end_sample, 0]

# # Konversi ke binary
with open("ecg_binary_new.txt", "w") as f:
    # f.write("SampleIndex, BinaryValue\n")
    for idx, amp in zip(sample_indices, amplitudes):
        binary_val = decimal_to_custom_16bit(amp)
        f.write(f"{binary_val}\n")


# --- Tampilkan plot ---
# time_axis = sample_indices / sampling_rate  # ubah sample index ke detik
# plt.figure(figsize=(12, 4))
# plt.plot(time_axis, amplitudes, label='Raw ECG')
# plt.xlabel('Time (s)')
# plt.ylabel('Amplitude (mV)')
# plt.title('Segment of ECG Signal: 5-10 Seconds')
# plt.grid(True)
# plt.legend()
# plt.tight_layout()
# plt.show()
