clear; clc; close all;

fc = ask('Carrier frequency (MHz)', 900);
Pt = ask('BS transmit power before splitting (dBm)', 43);
Smin = ask('Receiver sensitivity (dBm)', -100);
n = ask('Path loss exponent', 3.5);
Rin = ask('Cell radius R (km), 0 to compute from link budget', 0);
S = ask('Cell splitting factor (new radius = R/S)', 2);
N = ask('Cluster size N', 7);
Ctot = ask('Total channels available to the system', 280);

d0 = 0.1;
PL0 = 20*log10(d0) + 20*log10(fc) + 32.44;
if Rin <= 0
    R = d0*10^((Pt - PL0 - Smin)/(10*n));
else
    R = Rin;
end
side = ask('Side of the service area (km)', round(6*R, 1));
if side <= 0
    error('Service area side must be positive');
end

R2 = R/S;
Pt2 = Pt - 10*n*log10(S);
A1 = 3*sqrt(3)/2*R^2;
A2 = 3*sqrt(3)/2*R2^2;
h = side/2;

[x1, y1] = hexgrid(R, h);
[x2, y2] = hexgrid(R2, h);
n1 = numel(x1);
n2 = numel(x2);

cpc = Ctot/N;
cap1 = n1*cpc;
cap2 = n2*cpc;

fprintf('\nOriginal cell radius              : %.3f km\n', R);
fprintf('Original hexagonal cell area      : %.3f km^2\n', A1);
fprintf('New cell radius                   : %.3f km\n', R2);
fprintf('New hexagonal cell area           : %.3f km^2\n', A2);
fprintf('Area ratio (old/new)              : %.2f\n', A1/A2);
fprintf('Transmit power reduction          : %.2f dB (new Pt = %.2f dBm)\n', 10*n*log10(S), Pt2);
fprintf('Cells in service area (old / new) : %d / %d\n', n1, n2);
fprintf('Channels per cell                 : %.2f\n', cpc);
fprintf('System capacity (old / new)       : %.0f / %.0f channels\n', cap1, cap2);
fprintf('Capacity gain                     : %.2fx\n', cap2/cap1);

figure('Color', 'w', 'Position', [80 60 1100 800]);

subplot(2,2,1);
drawgrid(x1, y1, R, [0.8 0.9 1], 'b', 1);
hold on;
rectangle('Position', [-h -h side side], 'EdgeColor', 'r', 'LineStyle', '--', 'LineWidth', 1.3);
axis equal; axis([-h - R h + R -h - R h + R]);
xlabel('km'); ylabel('km');
title(sprintf('Before splitting: R = %.2f km, %d cells', R, n1));

subplot(2,2,2);
drawgrid(x2, y2, R2, [0.85 1 0.85], [0.2 0.5 0.2], 0.8);
hold on;
drawgrid(x1, y1, R, 'none', 'b', 1.8);
rectangle('Position', [-h -h side side], 'EdgeColor', 'r', 'LineStyle', '--', 'LineWidth', 1.3);
axis equal; axis([-h - R h + R -h - R h + R]);
xlabel('km'); ylabel('km');
title(sprintf('After splitting: R'' = %.2f km, %d cells', R2, n2));

subplot(2,2,3);
d = linspace(d0, 2.2*R, 300);
P1 = Pt - PL0 - 10*n*log10(d/d0);
P2 = Pt2 - PL0 - 10*n*log10(d/d0);
plot(d, P1, 'b', 'LineWidth', 1.5, 'DisplayName', sprintf('Original (%.1f dBm)', Pt)); hold on;
plot(d, P2, 'Color', [0.2 0.6 0.2], 'LineWidth', 1.5, 'DisplayName', sprintf('After split (%.1f dBm)', Pt2));
plot([d(1) d(end)], [Smin Smin], 'r--', 'LineWidth', 1.3, 'DisplayName', 'Sensitivity');
plot([R R], ylim, 'b:', 'HandleVisibility', 'off');
plot([R2 R2], ylim, ':', 'Color', [0.2 0.6 0.2], 'HandleVisibility', 'off');
grid on; legend('Location', 'northeast');
xlabel('Distance from BS (km)'); ylabel('Received power (dBm)');
title('Cell coverage radius from link budget');

subplot(2,2,4);
bh = bar([cap1 cap2]);
bh.FaceColor = 'flat';
bh.CData = [0.2 0.4 0.9; 0.2 0.6 0.2];
xticklabels({'Before', 'After'});
text(1:2, [cap1 cap2], arrayfun(@(v) sprintf('%.0f', v), [cap1 cap2], 'UniformOutput', false), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
grid on; ylabel('Channels in service area');
title(sprintf('Capacity gain = %.2fx', cap2/cap1));

function [x, y] = hexgrid(R, h)
qm = ceil(h/(sqrt(3)*R)) + ceil(h/(1.5*R)) + 2;
rm = ceil(h/(1.5*R)) + 1;
[q, r] = meshgrid(-qm:qm, -rm:rm);
x = sqrt(3)*R*(q + r/2);
y = 1.5*R*r;
keep = abs(x) <= h & abs(y) <= h;
x = x(keep);
y = y(keep);
end

function drawgrid(x, y, R, fcol, ecol, lw)
ang = (30:60:330)*pi/180;
X = x(:) + R*cos(ang);
Y = y(:) + R*sin(ang);
patch('XData', X', 'YData', Y', 'FaceColor', fcol, ...
    'EdgeColor', ecol, 'LineWidth', lw);
end

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
