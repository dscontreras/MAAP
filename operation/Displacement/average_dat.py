""" Averages columns in .dat files. Assumes only four columns in file """

file = open('not_drawnow_times.dat')
values = []
for line in file:
    values += line.split()
cols = []
for value in values:
    cols += value.split(',')
i = 0
average1 = []
average2 = []
average3 = []
average4 = []
while i < len(cols):
    average1.append(float(cols[i]))
    i += 1
    average2.append(float(cols[i]))
    i += 1
    average3.append(float(cols[i]))
    i += 1
    average4.append(float(cols[i]))
    i += 1
averages = []
averages.append(sum(average1) / len(average1))
averages.append(sum(average2) / len(average2))
averages.append(sum(average3) / len(average3))
averages.append(sum(average4) / len(average4))

print(averages)

