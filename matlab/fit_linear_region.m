function [sse, y_hat] = fit_linear_region(x,tdata,ydata)


y_hat = x(1)*tdata+x(2);
sse = sum(abs(ydata - y_hat).^2);

end