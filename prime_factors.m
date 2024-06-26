function factors = prime_factors(n)
    % prime_factors computes the prime factors of a given number n
    % Input: n - the number to factorize
    % Output: factors - a vector containing the prime factors of n
    
    factors = []; % Initialize an empty array to store the factors
    p = 2; % Start with the smallest prime number
    
    while n > 1
        while mod(n, p) == 0
            factors = [factors p]; % Append p to the factors list
            n = n / p; % Divide n by p
        end
        p = p + 1; % Increment p
        % Optimization: If p^2 > n and n > 1, then n itself is prime
        if p^2 > n && n > 1
            factors = [factors n];
            break;
        end
    end
end
