function next_last_zero_integer = nearest_last_zero_integer(number)
    % 计算给定数的最后一位数字
    last_digit = mod(number, 10);
    
    % 如果最后一位数字为0，直接返回给定数
    if last_digit == 0
        next_last_zero_integer = number;
    else
        % 否则找到大于给定数且最后一位为0的整数
        next_last_zero_integer = number + (10 - last_digit);
    end
end
