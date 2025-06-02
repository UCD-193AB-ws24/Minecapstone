# Problem Set #8
## Problem 1
A chemist measures the temperature of a solution in Celsius. The measurement, denoted C, is normally distributed with mean 40 and variance 1. The measurement is converted to Fahrenheit by the equation F = 1.8C + 32. What is the distribution of F? 

*Hint: It is a normal distribution and you only need to find the parameters associated with this normal distribution.*

$E[F] = 1.8E[C] + 32 = 72 + 32 = 104$

$Var[F] = (1.8)^2 Var[C] = 3.24$


## Problem 2

Let X be the distance from the origin for a randomly chosen point in dartboard with radius 2. The cumulative distribution function for this random variable is:

$$F_X(x) = \begin{cases}
\frac{x^2}{4} & \text{if } 0 \leq x \leq 2 \\
0 & \text{if } x < 0 \\
1 & \text{if } x \geq 2
\end{cases}$$

(a) Find the probability density function $f_X$ for this random variable.

$f_X(x) = \frac{d}{dx} F_X(x) = \begin{cases}
\frac{x}{2} & \text{if } 0 < x < 2 \\
0 & \text{if } x < 0 \\
0 & \text{if } x \geq 2
\end{cases}$

(b) Find the expectation of X.

$E[X]= \int_{-\infty}^\infty x f_X(x) dx= \int_0^2 x \frac{x}{2} dx = \int_0^2 \frac{x^2}{2} dx = \frac{1}{2} \cdot \frac{x^3}{3} \bigg|_0^2 = \frac{1}{2} \cdot \frac{8}{3} = \frac{4}{3}$

(c) Find the variance of X.

$\text{Var}(X) = E[X^2] - (E[X])^2$

$E[X^2] = \int_{-\infty}^\infty x^2 f_X(x) dx = \int_0^2 x^2 \frac{x}{2} dx = \int_0^2 \frac{x^3}{2} dx = \frac{1}{2} \cdot \frac{x^4}{4} \bigg|_0^2 = \frac{1}{2} \cdot 4 = 2$

$\text{Var}(X) = 2 - \left(\frac{4}{3}\right)^2 = \frac{2}{9}$

(d) 100 darts are thrown at the dart board and land randomly on the dart board, independent of one another. Let $X_1, X_2, \ldots, X_{100}$ be the distances from the center. Let $A = \frac{X_1 + X_2 + \ldots + X_{100}}{100}$ be the average distance of these 100 darts from the center. Find $E[A]$ and $\text{var}(A)$.

$E[A] = E[\frac{1}{100} \sum_{i=1}^{100} X_i] = \frac{1}{100} \sum_{i=1}^{100} E[X_i] = \frac{1}{100} \sum_{i=1}^{100} \frac{4}{3} = \frac{1}{100} \cdot 100 \cdot \frac{4}{3} = \frac{4}{3}$

# Problem 3
Let U be uniformly distributed on the interval [0, 1] and $X = -\ln(1 - U)$. Show that X is exponentially distributed with rate $\lambda = 1$.

$\text{CDF: } F_X(x) = P(X \leq x) = P(-\ln(1 - U) \leq x) = P(1 - U \geq e^{-x}) = P(U \leq 1 - e^{-x})$

Since U is uniformly distributed on [0,1], $P(U \leq u)=u \text{ for } 0 \leq u \leq 1$.

Thus, $F_X(x)=u=1-e^{-x}$ for $u \in [0,1]$.

To get the pdf, differentiate the cdf:

$f_X(x) = \frac{d}{dx} F_X(x) = \frac{d}{dx} (1 - e^{-x}) = e^{-x}$.

X is exponentially distributed with rate $\lambda = 1$ since the pdf matches the form $f_X(x) = \lambda e^{-\lambda x}$ for $\lambda = 1$.

# Problem 4
Seeds of a plant species are dispersed by two species of ants. The distance (in kilometers) that a seed is dispersed by one plant species is exponentially distributed with rate parameter $\lambda = 10$, and exponentially distributed with rate $\lambda = 20$ by the other ant species. Let X be the distance a randomly selected seed was dispersed. If a seed is equally likely to be dispersed by either ant species, then the pdf for X is:

$$f_X(x) = \begin{cases}
5e^{-10x} + 10e^{-20x} & \text{for } x > 0 \\
0 & \text{else}
\end{cases}$$

(a) Find the cdf $F_X$ for X.

$F_X(x) = \int_0^xf_X(s) ds = \int_0^x (5e^{-10s} + 10e^{-20s}) ds$

$=5\int_0^x e^{-10s} ds + 10\int_0^x e^{-20s} ds$

$=5\cdot(\frac{1}{10} e^{-10s})\bigg|_0^x + 10\cdot(\frac{1}{20} e^{-20s})\bigg|_0^x$

$=\frac{1}{2} e^{-10x} + \frac{1}{2} e^{-20x}$

Thus,

$F_X(x) = \begin{cases}
\frac{1}{2} e^{-10x} + \frac{1}{2} e^{-20x} & \text{for } x > 0 \\
0 & \text{else}
\end{cases}$

(b) Find $E[X]$. *Hint: We showed in class that $\int_0^{\infty} \lambda xe^{-\lambda x}dx = \frac{1}{\lambda}$.*

$E[X] = \int_0^{\infty} x f_X(x) dx = \int_0^{\infty} x (5e^{-10x} + 10e^{-20x}) dx$`

$= 5\int_0^{\infty} x e^{-10x} dx + 10\int_0^{\infty} x e^{-20x} dx$

From hint,

$= 5\cdot \frac{1}{10^2} + 10\cdot \frac{1}{20^2} = \frac{3}{40}$

# Problem 5
A gene transcribes a protein at rate $\lambda = 2$ per minute.

(a) Find the probability that both the first and second transcription events take less than 1/2 a minute.

Let $T_1$ and $T_2$ be the times of the first and second transcription events, respectively.

They both follow an exponential distribution with rate $\lambda = 2$. The probability that a single transcription event occurs in less than $t$ minutes is given by:

$P(T_1 < 0.5 \text{ and } T_2 < 0.5) = P(T_2 < 0.5)$

Because if $T_2 < 0.5$, then $T_1$ must also be less than $0.5$.

$P(T_2 < 0.5) = 1 - e^{-\lambda t} = 1 - e^{-2 \cdot 0.5} = 1 - e^{-1} \approx 0.6321$

(b) Find the expectation and variance of the number of transcription events by time $t = 3$.

$E[N(t)] = \lambda t = 2 \cdot 3 = 6$

$\text{Var}(N(t)) = \lambda t = 2 \cdot 3 = 6$

# Problem 6
A 911 call center receives emergency calls at a rate of $\lambda = 5$ per hour.

(a) Find the expectation and variance of the number of calls during an eight hour shift.

$E[\text{calls at t=8}] = \lambda t = 5 \cdot 8 = 40$

$\text{Var}(\text{calls at t=8}) = \lambda t = 5 \cdot 8 = 40$

(b) Find the probability that there are more than 40 calls during an eight hour shift.

$P(\text{more than 40 calls}) = P(\text{calls at t=8} > 40)$

$P(\text{calls at t=8} > 40) = 1 - P(\text{calls at t=8} \leq 40)$

Assuming the number of calls follows a Poisson distribution with parameter $\lambda t = 40$:

$P(\text{calls at t=8} > 40) = 1- e^{-40} \sum_{k=0}^{40} \frac{40^ke^{-40}}{k!}$

(c) Find the probability that the first call on a shift occurs within the first ten minutes.

$P(\text{First call within 10 minutes}) = P(T < 10 \text{ minutes}) = P(T < 1/6 \text{ hours})$

$= 1 - e^{-\lambda t} = 1 - e^{-5 \cdot (1/6)} = 1 - e^{-5/6} = 0.5654$