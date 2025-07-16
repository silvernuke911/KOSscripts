weights = [4,3,3,3,4]
grades = [1,2.5,2.5,3,1.25]

fg=0
sum_w = 0
for g, w in zip(grades,weights):
    sum_w += w
    fg += g*w 
fg = fg/sum_w
print(fg)