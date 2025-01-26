def matcher(T, P):
	s = 0
	j = 0
	while s + j < len(T):
		if P[j] == T[s + j]:
			if j == len(P) - 1:
				return s
			j += 1
		else:
			s += 1

print(matcher("abc", "abc"))