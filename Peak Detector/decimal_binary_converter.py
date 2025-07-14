def float_to_custom_binary(float_value):
    # Determine the sign bit
    sign_bit = 0 if float_value >= 0 else 1

    # Get the absolute value of the float for further processing
    abs_value = abs(float_value)

    # Separate the integer and fractional parts
    integer_part = int(abs_value)
    fractional_part = abs_value - integer_part

    # Convert the integer part to binary (4 bits)
    integer_binary = format(integer_part & 0b1111, '04b')

    # Convert the fractional part to binary (26 bits)
    fractional_binary = ''
    for _ in range(11):
        fractional_part *= 2
        bit = int(fractional_part)
        fractional_binary += str(bit)
        fractional_part -= bit

    # Combine all parts into a single binary string
    custom_binary = f"{sign_bit}{integer_binary}{fractional_binary}"

    # Ensure the binary string is exactly 32 bits long by padding with zeros
    # The total length should be 32 bits, so we need to add 1 bit for the sign
    # and 4 bits for the integer part, making it 5 bits, leaving 27 bits for the mantissa
    #if len(custom_binary) < 32:
    #    custom_binary = custom_binary.ljust(32, '0')  # Pad with zeros to the right if needed

    return custom_binary

input = 10.4443
biner = float_to_custom_binary(input)
print(f"Angka biner adalah {biner}")
