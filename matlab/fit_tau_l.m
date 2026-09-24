function [err,tau_l_fit] = fit_tau_l(P,p_values,tau_l_data)

id_P = p_values <= P(1);


tau_l_fit = real(1./(P(1) - p_values).^P(2))*P(3) + P(4);
err = rmse(tau_l_data(id_P),tau_l_fit(id_P));


end


