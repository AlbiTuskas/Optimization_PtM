function init = generateRandomInitialValues(lowerBound, upperBound, len)

init = lowerBound + (upperBound - lowerBound) .* rand(length(lowerBound),1);