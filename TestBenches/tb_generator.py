import random

def get_s():
    s = int(input("Enter the value of filter (3 or 5): "))
    if s != 3 and s != 5:
        print("Invalid value. Please enter 3 or 5.")
        s = get_s()
    return s

# Function to get user input for k
def get_user_input():
    k = int(input("Enter the value of k: "))
    return k

# Function to generate 14 random values between -128 and 127
def generate_random_values_14():
    values = [random.randint(-128, 127) for _ in range(14)]
    return values

# Function to generate k random values between -128 and 127
def generate_random_values_k(k):
    random_values = [random.randint(-128, 127) for _ in range(k)]
    return random_values

def calculate_r_tot(sum_value, s):
    
    r_tot = 0
    r_tot = (sum_value >> 6) + (sum_value >> 10)

    if s == 3:
        r_tot += (sum_value >> 4) + (sum_value >> 8)
        if sum_value < 0:
            r_tot += 4
    else:
        if sum_value < 0:
            r_tot += 2

    return r_tot

def generate_validation_values(c_values, random_values, s, k):
    
    if s == 3 :
        start=-2
        center = 3
        div = 12
    else:
        start=-3
        center = 10
        div = 60
    
    j=start
    i=0
    sum = 0
    validation_values = []
    
    while i < k:
        if j <= -start and j >= start:
            if i+j >= 0 and i+j < k :
                sum += c_values[center+j] * random_values[i+j]
            else:
                sum += 0
            j += 1
        else:
            #value = sum/div
            value = calculate_r_tot(sum, s)
            
            if value < -128:
                value = -128
                
            elif value > 127:
                value = 127
                
            #validation_values.append(round(value))
            validation_values.append(value)
            
            j=start
            sum=0
            i += 1
            
    return validation_values
 
# Main function
def main():
    s= get_s()
    k = get_user_input()
    c_values = generate_random_values_14()
    random_values = generate_random_values_k(k)
    validation_values = generate_validation_values(c_values, random_values, s, k)
    
    print("C values:", c_values)
    print("Random INPUT values:", random_values)
    print("Generate OUTPUT values:", validation_values)

if __name__ == "__main__":
    main()
