clear; clc; close all;

fc = ask('Carrier frequency (MHz)', 900);
Pt = ask('Transmit power (dBm)', 43);
Gt = ask('Transmit antenna gain (dBi)', 0);
Gr = ask('Receive antenna gain (dBi)', 0);
Ls = ask('System losses (dB)', 0);
Smin = ask('Receiver sensitivity (dBm)', -100);
dmin = ask('Minimum distance (km)', 0.1);
dmax = ask('Maximum distance (km)', 50);
dcalc = ask('Distance for point calculation (km)', 5);

c = 3e8;
lambda = c/(fc*1e6);
fspl = @(d, f) 20*log10(d) + 20*log10(f) + 32.44;

PLc = fspl(dcalc, fc);
PLexact = 20*log10(4*pi*dcalc*1e3/lambda);
Prc = Pt + Gt + Gr - Ls - PLc;
Prw = 10^((Prc - 30)/10);
dMax = 10^((Pt + Gt + Gr - Ls - Smin - 32.44 - 20*log10(fc))/20);

fprintf('\nWavelength                         : %.4f m\n', lambda);
fprintf('Free-space path loss at %.2f km    : %.2f dB (exact formula %.2f dB)\n', dcalc, PLc, PLexact);
fprintf('Received power at %.2f km          : %.2f dBm (%.3e W)\n', dcalc, Prc, Prw);
fprintf('Maximum range for %.1f dBm         : %.2f km\n', Smin, dMax);
if Prc >= Smin
    fprintf('Link margin at %.2f km             : %.2f dB (link OK)\n', dcalc, Prc - Smin);
else
    fprintf('Link margin at %.2f km             : %.2f dB (below sensitivity)\n', dcalc, Prc - Smin);
end

d = logspace(log10(dmin), log10(dmax), 400);

figure('Color', 'w', 'Position', [80 60 1100 780]);

subplot(2,2,1);
hold on;
for f = unique([450 900 1800 2100 2600 fc])
    semilogx(d, fspl(d, f), 'LineWidth', 1.4, 'DisplayName', sprintf('%g MHz', f));
end
set(gca, 'XScale', 'log');
plot(dcalc, PLc, 'ko', 'MarkerFaceColor', 'k', 'HandleVisibility', 'off');
grid on; legend('Location', 'southeast');
xlabel('Distance (km)'); ylabel('Path loss (dB)');
title('Free-space path loss vs distance');

subplot(2,2,2);
Pr = Pt + Gt + Gr - Ls - fspl(d, fc);
semilogx(d, Pr, 'b', 'LineWidth', 1.6); hold on;
semilogx([dmin dmax], [Smin Smin], 'r--', 'LineWidth', 1.4);
if dMax >= dmin && dMax <= dmax
    plot(dMax, Smin, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 9);
    text(dMax, Smin + 6, sprintf('  d_{max} = %.2f km', dMax));
end
plot(dcalc, Prc, 'ko', 'MarkerFaceColor', 'k');
grid on;
xlabel('Distance (km)'); ylabel('Received power (dBm)');
title(sprintf('Received power at %g MHz', fc));
legend('P_r', 'Sensitivity', 'Location', 'northeast');

subplot(2,2,3);
fr = linspace(100, 3000, 300);
hold on;
for dd = unique([0.5 1 5 10 dcalc])
    plot(fr, fspl(dd, fr), 'LineWidth', 1.4, 'DisplayName', sprintf('%g km', dd));
end
grid on; legend('Location', 'southeast');
xlabel('Frequency (MHz)'); ylabel('Path loss (dB)');
title('Free-space path loss vs frequency');

subplot(2,2,4);
Ptr = 20:1:60;
hold on;
for f = unique([450 900 1800 2100 fc])
    plot(Ptr, 10.^((Ptr + Gt + Gr - Ls - Smin - 32.44 - 20*log10(f))/20), 'LineWidth', 1.4, ...
        'DisplayName', sprintf('%g MHz', f));
end
set(gca, 'YScale', 'log');
grid on; legend('Location', 'southeast');
xlabel('Transmit power (dBm)'); ylabel('Maximum range (km)');
title(sprintf('Maximum range for %.0f dBm sensitivity', Smin));

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
