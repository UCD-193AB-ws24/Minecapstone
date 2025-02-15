# Following program is the python implementation of
# Rabin Karp Algorithm given in CLRS book

# d is the number of characters in the input alphabet
d = 256

# pat -> pattern
# txt -> text
# q -> A prime number


def search(pat, txt, q):
    M = len(pat)
    N = len(txt)
    i = 0
    j = 0
    p = 0 # hash value for pattern
    t = 0 # hash value for txt
    h = pow(d, M-1) % q

    # Calculate the hash value of pattern and first window of text
    for i in range(M):
        p = (d*p + ord(pat[i])) % q
        t = (d*t + ord(txt[i])) % q

    # Slide the pattern over text one by one
    for i in range(N-M+1):
        # Check the hash values of current window of text and
        # pattern if the hash values match then only check
        # for characters one by one
        if p == t:
            # Check for characters one by one
            for j in range(M):
                if txt[i+j] != pat[j]:
                    break
                else:
                    j += 1

            # if p == t and pat[0...M-1] = txt[i, i+1, ...i+M-1]
            if j == M:
                print("Pattern found at index " + str(i))

        # Calculate hash value for next window of text: Remove
        # leading digit, add trailing digit
        if i < N-M:
            t = (d*(t-ord(txt[i])*h) + ord(txt[i+M])) % q

            # We might get negative values of t, converting it to
            # positive
            if t < 0:
                t = t+q


from collections import defaultdict

def build_subpattern_map(patterns):
    sub_map = {}
    for p in patterns:
        sub_map[p] = []
        for q in patterns:
            if q != p and len(q) < len(p) and q in p:
                sub_map[p].append(q)
    return sub_map

def search_multiple(patterns, txt, q):
    # Sort patterns by descending length
    patterns.sort(key=len, reverse=True)
    sub_map = build_subpattern_map(patterns)

    pattern_groups = defaultdict(list)
    for pat in patterns:
        pattern_groups[len(pat)].append(pat)

    for length in sorted(pattern_groups.keys(), reverse=True):
        group = pattern_groups[length]
        N = len(txt)
        if N < length:
            continue
        h = pow(d, length-1) % q
        pattern_map = {}
        for pat in group:
            p_hash = 0
            for ch in pat:
                p_hash = (d * p_hash + ord(ch)) % q
            pattern_map.setdefault(p_hash, []).append(pat)

        t = 0
        for i in range(length):
            t = (d * t + ord(txt[i])) % q

        for i in range(N - length + 1):
            if t in pattern_map:
                for pat in pattern_map[t]:
                    if txt[i:i+length] == pat:
                        print("Pattern '{}' found at index {}".format(pat, i))
                        # Also report any subpatterns
                        for sp in sub_map[pat]:
                            print("Subpattern '{}' found at index {}".format(sp, i))
            if i < N - length:
                t = (d*(t - ord(txt[i]) * h) + ord(txt[i+length])) % q
                if t < 0:
                    t += q


# Driver Code
if __name__ == '__main__':
    pat = "GEEK"

    # A prime number
    q = 101

    # Function Call
    # search(pat, txt, q)
    txt = "abcdabcdabcd"
    patterns = ["abcd", "abc"]
    search_multiple(patterns, txt, q)