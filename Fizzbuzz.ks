//FizzBuzz Programming Language
set x to 0.

until x = 100 {
    set x to x+1.
    if mod(x,(3*5))=0 {
        print "Fizzbuzz".
    } else if mod(x,3)=0 {
        print "Fizz".
    } else if mod(x,5)=0 {
        print "Buzz".
    } else {
        print x. 
    }
}

