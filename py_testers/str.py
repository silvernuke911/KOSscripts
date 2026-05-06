import time
import random

# Your function
def str_to_int(numstring):
    result = 0
    for char in numstring:
        result = result * 10 + ord(char) - ord("0")
    return result


# Generate 10,000 random long integers (as strings)
N = 100000
NUM_DIGITS = 20  # adjust length of "long ints"

data = [
    ''.join(str(random.randint(0, 9)) for _ in range(NUM_DIGITS))
    for _ in range(N)
]


# Timer decorator (adapted for dataset)
def timer_dataset(func):
    def wrapper(dataset):
        start = time.perf_counter()
        
        for item in dataset:
            func(item)
        
        end = time.perf_counter()
        total_time = end - start
        avg_time = total_time / len(dataset)
        
        print(f"{func.__name__}:")
        print(f"  Total time over {len(dataset)} runs: {total_time:.6f} s")
        print(f"  Average time per run: {avg_time:.12f} s\n")
        
    return wrapper


@timer_dataset
def test_custom(s):
    return str_to_int(s)


@timer_dataset
def test_builtin(s):
    return int(s)


# Run benchmarks
test_custom(data)
test_builtin(data)


print("Hello\b\b")     # Backspace: "Hel"
print("One\tTwo\tThree")  # Tab: "One   Two   Three"
print("Line1\nLine2")     # Newline
print("Col1\rCol2")        # Carriage return overwrites
print("\a")                # Makes your computer beep!