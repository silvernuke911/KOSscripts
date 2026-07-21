import numpy as np

def fizzbuzz():
    for i in range(1,100):
        if ((i%3 == 0) and (i%5 == 0)):
            print("Fizzbuzz")
        elif (i % 3 == 0):
            print("Fizz")
        elif (i % 5 == 0):
            print("Buzz")
        else:
            print(f"{i}")

fizzbuzz()
