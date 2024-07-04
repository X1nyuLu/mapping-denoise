% 定义混合高斯-洛伦兹函数
function y = mixed_gaussian_lorentzian(p, x)
    x0 = p(1);   
    Ag = p(2);      
    sigma = p(3);   
    Al = p(4);      
    gamma = p(5);   
    y0 = p(6);      
    
    gaussian_part = Ag * exp(-(x - x0).^2 / (2 * sigma^2));
    lorentzian_part = Al * gamma^2 ./ ((x - x0).^2 + gamma^2);
    y = gaussian_part + lorentzian_part + y0;
end