clear; clc; close all;

D = ask('Distance between the two base stations (km)', 2);
fc = ask('Carrier frequency (MHz)', 900);
Pt = ask('BS transmit power (dBm)', 43);
n = ask('Path loss exponent', 3.5);
sigma = ask('Shadowing standard deviation (dB)', 4);
dcorr = ask('Shadowing decorrelation distance (m)', 50);
H = ask('Handover hysteresis margin (dB)', 5);
Smin = ask('Minimum usable signal (dBm)', -100);
vkmh = ask('Mobile speed (km/h)', 60);
Ts = ask('Measurement interval (s)', 0.5);
seed = ask('Random seed', 1);

rng(seed);

d0 = 0.1;
PL0 = 20*log10(d0) + 20*log10(fc) + 32.44;
v = vkmh/3.6;
stepM = v*Ts;
x = 0:stepM/1000:D;
K = numel(x);

a = exp(-stepM/dcorr);
s1 = zeros(1, K); s2 = zeros(1, K);
s1(1) = sigma*randn; s2(1) = sigma*randn;
for k = 2:K
    s1(k) = a*s1(k-1) + sqrt(1 - a^2)*sigma*randn;
    s2(k) = a*s2(k-1) + sqrt(1 - a^2)*sigma*randn;
end

m1 = Pt - PL0 - 10*n*log10(max(x, d0)/d0);
m2 = Pt - PL0 - 10*n*log10(max(D - x, d0)/d0);
P1 = m1 + s1;
P2 = m2 + s2;

serveA = 1 + (P2 > P1);
serveH = zeros(1, K);
s = 1;
for k = 1:K
    if s == 1 && P2(k) > P1(k) + H
        s = 2;
    elseif s == 2 && P1(k) > P2(k) + H
        s = 1;
    end
    serveH(k) = s;
end

hoA = find(diff(serveA) ~= 0) + 1;
hoH = find(diff(serveH) ~= 0) + 1;
PsA = P1.*(serveA == 1) + P2.*(serveA == 2);
PsH = P1.*(serveH == 1) + P2.*(serveH == 2);

fprintf('\nPath loss at d0 = %.1f km        : %.2f dB\n', d0, PL0);
fprintf('Ideal handover point (no fading): %.3f km\n', D/2);
fprintf('Handovers, no hysteresis        : %d\n', numel(hoA));
fprintf('Handovers, %.1f dB hysteresis    : %d\n', H, numel(hoH));
fprintf('Outage samples, no hysteresis   : %.2f %%\n', 100*mean(PsA < Smin));
fprintf('Outage samples, hysteresis      : %.2f %%\n', 100*mean(PsH < Smin));
if ~isempty(hoH)
    fprintf('First hysteresis handover at    : %.3f km\n', x(hoH(1)));
end

figure('Color', 'w', 'Position', [80 60 950 800]);

subplot(3,1,1);
plot(x, P1, 'b', 'LineWidth', 1.1, 'DisplayName', 'BS1 RSS'); hold on;
plot(x, P2, 'r', 'LineWidth', 1.1, 'DisplayName', 'BS2 RSS');
plot(x, m1, 'b--', 'DisplayName', 'BS1 mean');
plot(x, m2, 'r--', 'DisplayName', 'BS2 mean');
plot([0 D], [Smin Smin], 'k:', 'LineWidth', 1.3, 'DisplayName', 'Minimum signal');
for k = hoH
    plot([x(k) x(k)], ylim, 'g-', 'LineWidth', 1.2, 'HandleVisibility', 'off');
end
grid on; legend('Location', 'northeastoutside');
xlabel('Distance from BS1 (km)'); ylabel('RSS (dBm)');
title('Received signal strength from both base stations');

subplot(3,1,2);
stairs(x, serveA, 'm', 'LineWidth', 1.3, 'DisplayName', 'No hysteresis'); hold on;
stairs(x, serveH + 0.05, 'k', 'LineWidth', 1.3, 'DisplayName', sprintf('Hysteresis %.1f dB', H));
ylim([0.7 2.4]); yticks([1 2]); yticklabels({'BS1', 'BS2'});
grid on; legend('Location', 'northeastoutside');
xlabel('Distance from BS1 (km)'); ylabel('Serving BS');
title(sprintf('Serving base station (%d vs %d handovers)', numel(hoA), numel(hoH)));

subplot(3,1,3);
plot(x, PsA, 'm', 'DisplayName', 'No hysteresis'); hold on;
plot(x, PsH, 'k', 'LineWidth', 1.2, 'DisplayName', 'With hysteresis');
plot([0 D], [Smin Smin], 'r:', 'LineWidth', 1.3, 'DisplayName', 'Minimum signal');
grid on; legend('Location', 'northeastoutside');
xlabel('Distance from BS1 (km)'); ylabel('RSS of serving BS (dBm)');
title('Signal level seen by the mobile');

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
