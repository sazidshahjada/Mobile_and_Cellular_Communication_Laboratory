clear; clc; close all;

ni = round(ask('Shift parameter i', 2));
nj = round(ask('Shift parameter j', 1));
R = ask('Cell radius R (km)', 1);
n = ask('Path loss exponent', 4);

if ni < 0 || nj < 0 || (ni == 0 && nj == 0)
    error('i and j must be non-negative and not both zero');
end

N = ni^2 + ni*nj + nj^2;
D = R*sqrt(3*N);
Q = D/R;
SIR = 10*log10(Q^n/6);

fprintf('\nCluster size N = i^2 + ij + j^2 : %d\n', N);
fprintf('Co-channel reuse distance D     : %.3f km\n', D);
fprintf('Co-channel reuse ratio Q = D/R  : %.3f\n', Q);
fprintf('Worst-case SIR (6 interferers)  : %.2f dB\n', SIR);
fprintf('Fraction of channels per cell   : 1/%d\n', N);

K = ceil(sqrt(N)) + 2;
[q, r] = meshgrid(-K:K);
keep = abs(q + r) <= K;
q = q(keep); r = r(keep);
x = sqrt(3)*R*(q + r/2);
y = 1.5*R*r;
sN = (ni + nj)*q + nj*r;
tN = -nj*q + ni*r;
[~, ~, id] = unique([mod(sN, N) mod(tN, N)], 'rows');
cmap = hsv(N)*0.75 + 0.25;

c0 = find(q == 0 & r == 0);
dist = hypot(x - x(c0), y - y(c0));
co = find(id == id(c0) & dist > 1e-9);
[~, o] = sort(dist(co));
co = co(o(1:min(6, numel(co))));

figure('Color', 'w', 'Position', [100 100 800 700]);
hexcells(x, y, R, cmap(id, :), 0.5);
hold on;
hexcells(x([c0; co]), y([c0; co]), R, cmap(id([c0; co]), :), 2.5);
for k = 1:numel(id)
    text(x(k), y(k), num2str(id(k)), 'HorizontalAlignment', 'center', 'FontSize', 8);
end
for k = 1:numel(co)
    plot([x(c0) x(co(k))], [y(c0) y(co(k))], 'k--', 'LineWidth', 1.3);
end
if ~isempty(co)
    text((x(c0) + x(co(1)))/2, (y(c0) + y(co(1)))/2, sprintf('D = %.2f km', D), ...
        'HorizontalAlignment', 'center', 'BackgroundColor', 'w', 'FontWeight', 'bold');
end
axis equal off;
title(sprintf('Cluster size N = %d (i = %d, j = %d), D/R = %.3f', N, ni, nj, Q));

validN = [1 3 4 7 9 12 13 16 19 21];
Qv = sqrt(3*validN);

figure('Color', 'w', 'Position', [150 150 1000 420]);

subplot(1,2,1);
plot(validN, Qv, 'bo-', 'LineWidth', 1.5, 'MarkerFaceColor', 'b'); hold on;
plot(N, Q, 'rs', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
grid on;
xlabel('Cluster size N'); ylabel('Reuse ratio Q = D/R');
title('Reuse ratio vs cluster size');

subplot(1,2,2);
hold on;
for nn = unique([3 3.5 4 n])
    plot(validN, 10*log10(Qv.^nn/6), 'o-', 'LineWidth', 1.3, 'DisplayName', sprintf('n = %g', nn));
end
plot(N, SIR, 'rs', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'HandleVisibility', 'off');
grid on; legend('Location', 'northwest');
xlabel('Cluster size N'); ylabel('SIR (dB)');
title('Worst-case SIR vs cluster size');

function hexcells(x, y, R, col, lw)
ang = (30:60:330)*pi/180;
X = x(:) + R*cos(ang);
Y = y(:) + R*sin(ang);
patch(X', Y', permute(col, [3 1 2]), 'EdgeColor', 'k', 'LineWidth', lw);
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
