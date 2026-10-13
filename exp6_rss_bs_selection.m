clear; clc; close all;

L = ask('Side of the square service area (km)', 6);
nBS = round(ask('Number of base stations', 4));
if nBS <= 4
    defPos = [0.25 0.25; 0.75 0.30; 0.30 0.75; 0.75 0.80];
    defPos = defPos(1:nBS, :)*L;
else
    rng(3);
    defPos = rand(nBS, 2)*L;
end
pos = ask(sprintf('BS positions [x y; ...] in km (%d rows)', nBS), defPos);
Pt = ask('BS transmit power in dBm (scalar or vector)', 43);
fc = ask('Carrier frequency (MHz)', 900);
n = ask('Path loss exponent', 3.5);
sigma = ask('Shadowing standard deviation at the MS (dB)', 4);
Smin = ask('Receiver sensitivity (dBm)', -100);
ms = ask('MS position [x y] (km)', [0.4 0.4]*L);
seed = ask('Random seed', 1);

if size(pos, 1) ~= nBS
    error('Number of position rows must equal number of base stations');
end
if isscalar(Pt)
    Pt = repmat(Pt, nBS, 1);
end
Pt = Pt(:);
rng(seed);

d0 = 0.1;
PL0 = 20*log10(d0) + 20*log10(fc) + 32.44;

g = linspace(0, L, 200);
[X, Y] = meshgrid(g, g);
RSS = zeros(numel(g), numel(g), nBS);
for b = 1:nBS
    d = max(hypot(X - pos(b, 1), Y - pos(b, 2)), d0);
    RSS(:, :, b) = Pt(b) - PL0 - 10*n*log10(d/d0);
end
[Rmax, best] = max(RSS, [], 3);

dMS = max(hypot(ms(1) - pos(:, 1), ms(2) - pos(:, 2)), d0);
rssMS = Pt - PL0 - 10*n*log10(dMS/d0) + sigma*randn(nBS, 1);
[pm, sel] = max(rssMS);

served = Rmax >= Smin;
share = accumarray(best(served), 1, [nBS 1])/numel(best)*100;

fprintf('\nRSS at the MS from each base station:\n');
for b = 1:nBS
    fprintf('  BS%d: distance %.3f km, RSS %.2f dBm\n', b, dMS(b), rssMS(b));
end
if pm >= Smin
    fprintf('Selected base station: BS%d (%.2f dBm)\n', sel, pm);
else
    fprintf('No base station above sensitivity; best was BS%d (%.2f dBm) -> no service\n', sel, pm);
end
fprintf('Area covered above sensitivity: %.2f %%\n', 100*mean(served(:)));

cmap = lines(nBS);

figure('Color', 'w', 'Position', [80 60 1100 800]);

subplot(2,2,1);
imagesc(g, g, best); axis xy equal tight;
colormap(gca, cmap); caxis([0.5 nBS + 0.5]);
colorbar('Ticks', 1:nBS);
hold on;
plot(pos(:, 1), pos(:, 2), 'k^', 'MarkerFaceColor', 'w', 'MarkerSize', 9);
for b = 1:nBS
    text(pos(b, 1) + 0.08, pos(b, 2) + 0.08, sprintf('BS%d', b), 'FontWeight', 'bold');
end
plot(ms(1), ms(2), 'rp', 'MarkerFaceColor', 'r', 'MarkerSize', 12);
plot([ms(1) pos(sel, 1)], [ms(2) pos(sel, 2)], 'r-', 'LineWidth', 1.5);
xlabel('x (km)'); ylabel('y (km)');
title('Best-server map (strongest RSS)');

subplot(2,2,2);
imagesc(g, g, Rmax); axis xy equal tight;
colormap(gca, parula); colorbar;
hold on;
contour(X, Y, Rmax, [Smin Smin], 'k', 'LineWidth', 1.8);
plot(pos(:, 1), pos(:, 2), 'w^', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
plot(ms(1), ms(2), 'rp', 'MarkerFaceColor', 'r', 'MarkerSize', 12);
xlabel('x (km)'); ylabel('y (km)');
title('Strongest received signal (dBm), contour = sensitivity');

subplot(2,2,3);
bh = bar(rssMS);
bh.FaceColor = 'flat';
bh.CData = repmat([0.65 0.65 0.65], nBS, 1);
bh.CData(sel, :) = [0.85 0.33 0.1];
hold on;
plot([0.4 nBS + 0.6], [Smin Smin], 'r--', 'LineWidth', 1.5);
grid on; xticks(1:nBS);
xlabel('Base station'); ylabel('RSS at MS (dBm)');
title(sprintf('Base station selection for MS at (%.2f, %.2f) km', ms(1), ms(2)));

subplot(2,2,4);
bs = bar(share);
bs.FaceColor = 'flat';
bs.CData = cmap;
grid on; xticks(1:nBS);
xlabel('Base station'); ylabel('Served area (%)');
title('Share of service area won by each BS');

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
