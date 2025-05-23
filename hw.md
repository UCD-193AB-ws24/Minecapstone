# BIS|MAT 107 Problem Set #7

## 1. Consider a Markov chain of a sea turtle moving between the life stages of yearling (state 1), juvenile (state 2), adult (state 3), and death (state 4). 10% of the yearling survive and become juveniles, and the remaining 90% die. 80% of juveniles survive to the next year. Of the surviving juveniles 25% become adults. 80% of adults survive to the next year and remain adults.
* (a) Write down the transition matrix for the Markov chain.
    * $P = \begin{pmatrix} 0 & 0.1 & 0 & 0.9 \\
                           0 & 0.55 & 0.25 & 0.2 \\ 
                           0 & 0 & 0.8 & 0.2 \\ 
                           0 & 0 & 0 & 1 
            \end{pmatrix}$
* (b) Which states are recurrent? transient?
    * State 4 is recurrent. States 1, 2, and 3 are transient.
* (c) Let $N = min\{n \geq 0 : X_n = 4\}$ be the life span of an individual (i.e. the time until death). What is the expected life span of an individual starting as a hatchling $E[N |X_0 = 1]$? of an individual starting as a juvenile?
    * Let
        * $t_1 = E[N |X_0 = 1]$
        * $t_2 = E[N |X_0 = 2]$
        * $t_3 = E[N |X_0 = 3]$
    * Then,
        * $t_1 = 1 + (0.1t_2) + (0t_3) + (0.9t_4)= (1+ 0.1t_2) + (0) + (0) = 1+ 0.1t_2$
        * $t_2 = 1 + (0.55t_2) + (0.25t_3) + (0.2t_4) = 1 + (0.55t_2) + (0.25t_3) + (0.2\times0) = 1 + (0.55t_2) + (0.25t_3)$
        * $t_3 = 1 + (0.8t_3) + (0.2t_4) = 1 + (0.8t_3) + (0.2\times0)=1 + (0.8t_3)$
            * $1 = t_3-0.8t_3=0.2t_3\rightarrow t_3=\frac{1}{0.2}=5$
    * Therefore,
        * $t_2 = 1 + (0.55t_2) + (0.25\times5) \rightarrow 0.45t_2 = 1+ 1.25 \rightarrow t_2 = \frac{2.25}{0.45}=5$
    * And
        * $t_1 = 1 + 0.1t_2 = 1 + 0.1\times5 = 1 + 0.5 = 1.5$
* (d) Assume that a surviving adult reproduces with probability $0.5$. What is the probability an individual starting as a hatchling reproduces before dying? What is the answer for an individual starting as a juvenile? **Hint: You need to add another state (state 5) corresponding to an adult that survived and reproduced (i.e., set $p_{35} = 0.8 \times 0.5 = 0.4$ and change $p_{33}$ to $0.8 \times 0.5 = 0.4$) and force this state to be absorbing (i.e., $p_{55} = 1$)**
    * $P = \begin{pmatrix} 0 & 0.1 & 0 & 0.9 & 0 \\ 
                           0 & 0.55 & 0.25 & 0.2 & 0 \\ 
                           0 & 0 & 0.4 & 0.2 & 0.4 \\ 
                           0 & 0 & 0 & 1 & 0 \\ 
                           0 & 0 & 0 & 0 & 1 
            \end{pmatrix}$
    * Let
        * $r_1 = P(X_n \text{ reproduces before dying } | X_0 = 1)$
        * $r_2 = P(X_n \text{ reproduces before dying } | X_0 = 2)$
        * $r_3 = ...$
        * $r_4 = 0$
        * $r_5 = 1$
    * Then,
        * $r_1 = 0 + (0.1r_2) + (0.9\times0)$
        * $r_2 = 0 + (0.55r_2) + (0.25r_3) + (0.2\times0)$
        * $r_3 = 0 + (0.4r_3) + (0.2\times0) + (0.4 \times r_5) $
            * $r_3 = 0 + (0.4r_3) + (0) + (0.4 \times 1)$
            * $r_3 = (0.4r_3) + 0.4$
            * $0.6r_3=0.4\rightarrow r_3=\frac{0.4}{0.6}=\frac{2}{3}$
    * Therefore,
        * $r_2 = 0.55r_2 + 0.25\times\frac{2}{3} \rightarrow 0.45r_2 = \frac{1}{6} \rightarrow r_2 = \frac{1}{6} \times \frac{1}{0.45} = \frac{10}{27}$
    * And
        * $r_1 = 0.1\times \frac{10}{27} = \frac{1}{27}$
    * Finally, the probability of reproducing before dying is:
        * $r_1=P(X_n \text{ reproduces before dying } | X_0 = 1) = \frac{1}{27}$
        * $r_2=P(X_n \text{ reproduces before dying } | X_0 = 2) = \frac{10}{27}$
## 2. Consider a Markov chain with state space S = {1, 2, 3, 4} and transition matrix P = $\begin{pmatrix} 0.8 & 0.1 & 0.1 & 0.0 \\ 0.1 & 0.8 & 0.05 & 0.05 \\ 0.1 & 0.1 & 0.7 & 0.1 \\ 0.1 & 0.1 & 0.1 & 0.7 \end{pmatrix}$
* (a) If $X_0 = 1$, what is the expected time to reaching either state 3 or 4?
    * Let $T = min\{n \geq 0: X_n \in \{3,4\}\}$, $t_i = time to reach 3 or 4 starting from state i$.
    * $t_3 = 0$ and $t_4 = 0$.
    * Then,
        * $t_1 = 1+0.8t_1+0.1t_2+0.1t_3+0.0t_4=1+0.8t_1+0.1t_2$
        * $t_2 = 1+0.1t_1+0.8t_2+0.05t_3+0.05t_4=1+0.1t_1+0.8t_2$
    * Simplify
        * $0.2t_1=1+0.1t_2$
            * $\rightarrow t_1 = \frac{1+0.1t_2}{0.2} = 5 + 0.5t_2$
        * $0.2t_2=1+0.1t_1$
            * $\rightarrow t_2 = \frac{1+0.1t_1}{0.2} = 5 + 0.5t_1$
    * Substitute
        * $t_1 = 5+0.5(5 + 0.5t_1) = 5 + 2.5 + 0.25t_1$
            * $0.75t_1 = 7.5 \rightarrow t_1 = \frac{7.5}{0.75} = 10$
* (b) If $X_0 = 1$, what is the probability that the Markov chain hits 3 before 4?
    * Let $h_i = P(hit\ state\ 3\ before\ 4\ | X_0 = i)$.
    * $h_3 = 1$ and $h_4 = 0$.
    * Then,
        * $h_1 = 0.8h_1 + 0.1h_2 + 0.1h_3$
            * $h_1 = 0.8h_1 + 0.1h_2 + 0.1$
            * $0.2h_1 = 0.1h_2 + 0.1$
            * $h_1 = \frac{0.1h_2 + 0.1}{0.2} = 0.5h_2 + 0.5$
        * $h_2 = 0.1h_1 + 0.8h_2 + 0.05h_3 + 0.05h_4$
            * $h_2 = 0.1h_1 + 0.8h_2 + 0.05$
            * $0.2h_2 = 0.1h_1 + 0.05$
            * $h_2 = \frac{0.1h_1 + 0.05}{0.2} = 0.5h_1 + \frac{5}{20}$
    * Solve,
        * $h_1 = 0.5h_2 + 0.5$
            * $h_1 = 0.5(0.5h_1 + \frac{5}{20}) + 0.5$
            * $h_1 = 0.25h_1 + \frac{5}{40} + 0.5$
            * $0.75h_1 = \frac{25}{40}$
            * $h_1 = \frac{25}{30} = \frac{5}{6}$
    * Therefore, the probability of hitting state 3 before 4 is:
        * $h_1 = P(hit\ state\ 3\ before\ 4\ | X_0 = i) = \frac{5}{6}$
## 3. Consider the gambler’s ruin with probability p = 0.45 of winning. Assume the gambler initially has $20, makes $20 bets, and stops betting if they lose all of their money or reach $100. Find the probability that the gambler makes $100. Hint: Read the book.
* $p=0.45,\ 1-p=0.55,\ i=20,\ N=100$
* Esimated time to absorption $u_i$ is given by:
    * $u_i = 0$, for all recurrent states
    * $u_i = 1 + \sum_{j=1}^{m}p_{ij}u_j$, for all transient states
* The probability of winning starting from fortune $20, is the complement $1-a_i$ and is equal to:
    * $1-a_i = \begin{cases}
        \frac{1-\rho^{20}}{1-\rho^N} & \text{if}\ \rho\neq 1 \\
        \frac{i}{N} & \text{if}\ \rho = 1
      \end{cases}$
    * where $\rho = \frac{1-p}{p} = \frac{0.55}{0.45} = \frac{11}{9}$
* In this case,
    * $1-a_{20} = \frac{1-\frac{11}{9}^{20}}{1-\frac{11}{9}^{100}} = 1.04\times10^{-7}$ which as a percentage is $0.0000104\%$.
## 4. For the Davis precipitation data that you saw in lecture, the most common measured precipitation after 0 (dry day which occurred approximately 82% of the days) is 0.01 (light rain day which occurred approximately 2% of the days). Equating dry, light rain, and wet days with states 1, 2, 3, respectively, the Davis data gives (approximately) the following transition matrix for a Markov chain model of Davis rainfall: $P = \begin{pmatrix} 0.91 & 0.01 & 0.08 \\ 0.57 & 0.16 & 0.27 \\ 0.4 & 0.07 & 0.53 \end{pmatrix}$ Let $N = min\{n ≥ 0 : X_n = 3\}$ i.e. the time to the first rainy day. Find $E[N |X_0 = 1]$ i.e.  the average time to the first rainy day given that today is a dry day.
* Let
    * $t_3 = E[N |X_0 = 3] = 0$, since we are computting first-time passage to state 3
    * $t_2 = E[N |X_0 = 2] = 1 + 0.57t_1 + 0.16t_2 + 0.27t_3$
        * $ = 1 + 0.57t_1 + 0.16t_2$
    * $t_1 = E[N |X_0 = 1] = 1 + 0.91t_1+0.01t_2 + 0.08t_3$
        * $ = 1 + 0.91t_1+0.01t_2$
* Then,
    * $1 = 0.09t_1+0.01t_2$
    * $0.84t_2=1+0.57t_1$
        * $t_2 = \frac{1+0.57t_1}{0.84}$
* Substitute
    * $ 1 = 0.09t_1 + 0.01(\frac{0.57t_1+1}{0.84})$
    * $ 1 = 0.09t_1 + \frac{0.0057t_1+0.01}{0.84}$
    * $ 1 = 0.09t_1 + 0.0067t_1 + 0.0119$
    * $ 1 - 0.0119 = (0.09 + 0.0067)t_1$
    * $ 0.9881 = 0.0967t_1$
    * $ t_1 = \frac{0.9881}{0.0967} = 10.21$
        
## 5. Let $Xn$ be a branching process where the probability of having 0 offspring is 0.2, the probability of 1 offspring is 0.2, and probability of having two offspring is 0.6.
* (a) Write down the probability generating function for the offspring distribution.
    * Probability generation function given by $g(s)=E(s^Y)=\sum_{k=0}^{\infty}p_k s^k$ where $p_k$ is the probability of having k offspring and $s^k$ is a dummy variable.
    * So,
        * $g(s) = 0.2s^0 + 0.2s^1 + 0.6s^2$
* (b) Find the expected number of offspring.
    * Take the derivative
        * $g'(s) = 0.2 + 1.2s$
    * So,
        * $E[X] = g'(1) = 0.2 + 1.2(1) = 1.4$
* (c) Find the probability of eventual extinction assuming $X_0 = 1$.
    * $P(X_n=0) = g^n(0)$
        * Let q be the extinction probability, solve for q in the equation $g(q) = q$.
        * $0.2 + 0.2q + 0.6q^2 = q$
        * $0.6q^2 + 0.2q + 0.2 - q = 0$
        * $0.6q^2 - 0.8q + 0.2 = 0$
        * $q = \frac{0.8 \pm \sqrt{0.8^2 - 4(0.6)(0.2)}}{2(0.6)} = \frac{0.8 \pm \sqrt{0.64 - 0.48}}{1.2} = \frac{0.8 \pm \sqrt{0.16}}{1.2} = \frac{0.8 \pm 0.4}{1.2}$
        * $q_1 = \frac{1.2}{1.2} = 1, q_2 = \frac{0.4}{1.2} = \frac{1}{3}$
* (d) Find $P[X_3 = 0|X_0 = 5]$.
    * Compute $g^3(0)$
        * $g(0) = 0.2 + 0.2(0) + 0.6(0) = 0.2$
        * $g^2(0) = g(g(0)) = g(0.2) = 0.2 + 0.2(0.2) + 0.6(0.2)^2 = 0.264$
        * $g^3(0) = g(g^2(0)) = g(0.264) = 0.2 + 0.2(0.264) + 0.6(0.264)^2 = 0.2946$
    * Run generating function with 5 individuals
        * $g^3(0)^5 = 0.2946^5 = 0.0022$
## 6. Consider a branching process $Xn$ where the offspring distribution is given by the distribution of the number of failures of a geometric random variable with parameter p > 0.
* (a) Find the generating function g(s) for this distribution.
  * **Hint:** Recall for a geometric series, $\sum_{n=0}^{\infty} s^n = \frac{1}{1−s}$ wherever $|a| < 1$, and assume $|s| < 1.$
    * $g(s) = E(s^Y)=\sum_{k=0}^\infty p_k s^k = p\sum_{k=0}^\infty (1-p)^k s^k = p\sum_{k=0}^\infty [(1-p)s]^k$
    * Using Hint
        * $g(s) = p \frac{1}{1-(s(1-p))}=\frac{p}{1-s(1-p)}$
* (b) Find the mean number of offspring.
    * Calculate $\mu =g'(1).$
        * $g'(s) = p\times\frac{d}{ds}(\frac{1}{(1-s)(1-p)}) = p\times\frac{(1-p)}{(1-s(1-p))^2}$
    * Evaluate
        * $\mu = g'(1) = \frac{p(1-p)}{(1-(1-p))^2} = \frac{p(1-p)}{p^2} = \frac{1-p}{p}$
* (c) Find the extinction probability when the mean number of offspring is greater than 1 and $X_0 = 1$.
    * Need to solve for root of $q=g(q)$ given $\mu = \frac{1-p}{p} > 1$
    * This results in $\frac{1-p}{p}>1 \rightarrow 1-p >p \rightarrow p < \frac{1}{2}$
    * $q = g(q) = \frac{p}{1-q(1-p)}$
        * $q(1-q(1-p)) = p$
        * $q - q^2(1-p) = p$
        * $q^2(1-p) - q + p = 0$
        * $q = \frac{1 \pm \sqrt{1-4p(1-p)}}{2(1-p)}$
    * Simplify
        * $q = \frac{1 \pm \sqrt{(1-2p)^2}}{2(1-p)}$
        * $q = \frac{1 \pm (1-2p)}{2(1-p)}$
        * Solution 1:
            * $q = \frac{2(1-p)}{2(1-p)} = 1$
        * Solution 2:
            * $q = \frac{2p}{2(1-p)} = \frac{p}{1-p}$????????????????