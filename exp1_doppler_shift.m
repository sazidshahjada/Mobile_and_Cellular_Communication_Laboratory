clear; clc; close all;

c = 3e8;
fc = ask('Carrier frequency (MHz)', 900)*1e6;
vkmh = ask('Mobile velocity (km/h)', 60);
theta = ask('Angle between direction of motion and incoming wave (deg)', 0);
fdTol = ask('Maximum tolerable Doppler shift (Hz)', 100);

lambda = c/fc;
v = vkmh/3.6;
fdMax = v/lambda;
fd = fdMax*cosd(theta);
vMax = fdTol*lambda;
vMaxKmh = vMax*3.6;
Tc = 0.423/fdMax;

fprintf('\nWavelength                     : %.4f m\n', lambda);
fprintf('Mobile velocity                : %.2f m/s\n', v);
fprintf('Maximum Doppler shift          : %.2f Hz\n', fdMax);
fprintf('Doppler shift at %g deg        : %.2f Hz\n', theta, fd);
fprintf('Coherence time (0.423/fd_max)  : %.3f ms\n', Tc*1e3);
fprintf('Max velocity for %.1f Hz limit : %.2f m/s (%.2f km/h)\n', fdTol, vMax, vMaxKmh);

figure('Color', 'w', 'Position', [100 100 1000 700]);

subplot(2,2,1);
ang = -180:1:180;
plot(ang, fdMax*cosd(ang), 'b', 'LineWidth', 1.5); hold on;
plot(theta, fd, 'ro', 'MarkerFaceColor', 'r');
grid on; xlim([-180 180]);
xlabel('Angle \theta (deg)'); ylabel('Doppler shift (Hz)');
title(sprintf('Doppler shift vs arrival angle (%.0f km/h, %g MHz)', vkmh, fc/1e6));

subplot(2,2,2);
vr = linspace(0, max(150, 2*vkmh), 200);
freqs = unique([450 900 1800 2100 fc/1e6]);
hold on;
for f = freqs
    plot(vr, (vr/3.6)*f*1e6/c, 'LineWidth', 1.3, 'DisplayName', sprintf('%g MHz', f));
end
plot(vkmh, fdMax, 'ko', 'MarkerFaceColor', 'k', 'HandleVisibility', 'off');
grid on; legend('Location', 'northwest');
xlabel('Velocity (km/h)'); ylabel('Maximum Doppler shift (Hz)');
title('Maximum Doppler shift vs velocity');

subplot(2,2,3);
fr = linspace(300, 3000, 300);
plot(fr, fdTol*(c./(fr*1e6))*3.6, 'm', 'LineWidth', 1.5); hold on;
plot(fc/1e6, vMaxKmh, 'ko', 'MarkerFaceColor', 'k');
grid on;
xlabel('Carrier frequency (MHz)'); ylabel('Maximum velocity (km/h)');
title(sprintf('Maximum mobile velocity for f_d \\leq %.0f Hz', fdTol));

subplot(2,2,4);
vr2 = linspace(1, max(150, 2*vkmh), 200);
Tcr = 0.423./((vr2/3.6)/lambda)*1e3;
semilogy(vr2, Tcr, 'Color', [0.85 0.33 0.1], 'LineWidth', 1.5); hold on;
plot(vkmh, Tc*1e3, 'ko', 'MarkerFaceColor', 'k');
grid on;
xlabel('Velocity (km/h)'); ylabel('Coherence time (ms)');
title(sprintf('Channel coherence time at %g MHz', fc/1e6));

function v = ask(p, d)
s = input(sprintf('%s [default %s]: ', p, mat2str(d)), 's');
if isempty(strtrim(s))
    v = d;
else
    v = str2num(s);
    if isempty(v)
        v = d;
    end
end
end
