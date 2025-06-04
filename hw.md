# BIS|MAT 107 Problem Set #9

## 1.
Let $A_n$ be your wealth in year $n$. Assume $A_0 = \$100$ and $A_n = R_n A_{n-1}$. Consider two investment opportunities:

**Investment A** Each year, independent of other years, $R_n = 2$ with probability $0.4$, otherwise $R_n = 0.5$.

**Investment B** Each year, independent of other years, $R_n = 1.3$ with probability $0.4$, otherwise $R_n = 0.9$.

(a) Find $E(R_1)$ for both investments. For which one is the expected return greater?

* **For Investment A:** $E(R_1)=0.4*2+0.6*0.5=1.1$
* **For Investment B:** $E(R_2)=0.4*1.3+0.6*0.9=1.06$

(b) Find $\text{Var}(R_1)$ for both investments. For which one is the risk (i.e. variance) greater?

* 

(c) Find $E(\log R_1)$ for both investments. What do these values imply for the long-term fate of your wealth?

* 

(d) Discuss the answers you found for (a)-(c)

* 

## 2.
Two genotypes, A and B, experience fluctuating selection: good years for one genotype are bad years for the other, and vice versa. Let $F_n$ be the frequency of genotype A in the population in year $n$. In good years for genotype A its fitness is $A_n = 2$ while the fitness of genotype B in these years is $B_n = 1.4$. In bad years for genotype A its fitness is $A_n = 1$ while the fitness of genotype B in these years is $B_n = 1.6$. If the total population size is constant, a model of their dynamics is

$$F_n = \frac{A_n F_{n-1}}{A_n F_{n-1} + B_n(1 - F_{n-1})}$$

Assume good years and bad years are equally likely.

(a) Find $E(A_1)$ and $E(B_1)$. Based on only this information which genotype do you think will ultimately fixate.

* 

(b) [Not graded] Verify that $S_n = \ln \frac{F_n}{1-F_n} - \ln \frac{F_0}{1-F_0}$ defines a random walk with displacements $X_n = \ln \frac{A_n}{B_n}$.

* 

(c) Use your answer to (b) to determine which genotype ultimately fixates i.e. does $S_n \to -\infty$ or $\to \infty$ as $n \to \infty$?

* 

(d) Calculate $\text{Var}(A_1)$ and $\text{Var}(B_1)$. How might this explain the discrepancy between (a) and (b)?

* 

## 3.
While interned in Nazi-occupied Denmark in the 1940s, mathematician John Kerrich tossed a coin 10,000 times of which 5,067 turned up heads. Assuming the coin is fair, use the normal approximation to estimate the probability of getting between 4,933 and 5,067 heads after tossing a coin 10,000 times.

## 4.
Let $S_n = X_1 + X_2 + \ldots + X_n$ be the position (in microns) of a protein molecule in a cell at time $n$ (in seconds). Assume that $X_1, X_2, \ldots, X_n$ are i.i.d. with expectation $\mu = 0$ and variance $\sigma^2 = 60$.

(a) Suppose the diameter of the cell is 52 microns. Find $n$ (to the nearest integer) such that the standard deviation of $S_n$ is 52.

* 

(b) For the $n$ you found in (a), use a normal approximation to estimate $P[S_n \geq 52]$ i.e. the probability the protein has been transported across the cell in $n$ seconds.

* 

(c) Redo (a) and (b) for a cell with diameter 1,001 microns and $P[S_n \geq 1001]$.

* 

## 5. 
An individual wagers $1 per bet on a roulette table. Let $S_n$ be the amount they won at the $n$-th bet.

(a) The individual bets $n = 100$ times on reds where they win $1 with probability $\frac{18}{38}$ and lose $1 with probability $\frac{20}{38}$. Use the Central Limit Theorem to approximate $P[S_{100} \geq 10]$ i.e. they won at ten dollars.

* 

(b) The individual bets $n = 100$ times on a "street" where they win $11 with probability $\frac{3}{38}$ and lose $1 with probability $\frac{35}{38}$. Use the central limit theorem to approximate $P[S_{100} \geq 10]$ i.e. they won at ten dollars.

* 

## 6. 
Stacey and Taper (1992) used approximately a decade of data on the demography of the acorn woodpeckers to estimate its extinction risk (see optional part (c) for more details). From this data, one can derive a model of the form

$$A_n = R_n A_{n-1}$$

where $A$ is the abundance of female adults in year $n$ and $R_1, \ldots, R_n$ are positive i.i.d. random variables. For these random variables $E[R_1] = 0.96$, $E[\ln R_1] = -0.48$, $\text{var}[R_1] = 0.25$ and $\text{var}[\ln R_1] = 2$. Assume $A_0 = 100$ is the initial female adult woodpecker density. Use the Central Limit Theorem to estimate $P[A_{25} \geq 1]$.

* 