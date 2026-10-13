clear; clc; close all;

Btot = ask('Allocated spectrum per direction (MHz)', 25);
bw = ask('Channel bandwidth (kHz)', 200);
ul0 = ask('Uplink start frequency (MHz)', 890);
dup = ask('Duplex spacing (MHz)', 45);
N = round(ask('Cluster size N (3, 4, 7, 9, 12, 13, ...)', 7));
scheme = ask('Assignment scheme (1 = sequential blocks, 2 = interleaved)', 1);

[A, B] = meshgrid(0:10);
idx = find(A.^2 + A.*B + B.^2 == N & (A + B) > 0, 1);
if isempty(idx)
    error('N = %d is not a valid cluster size', N);
end
ni = A(idx); nj = B(idx);

M = floor(Btot*1000/bw);
if scheme == 1
    counts0 = floor(M/N) + ((1:N) <= mod(M, N));
    cellOf = repelem(1:N, counts0);
else
    cellOf = mod(0:M-1, N) + 1;
end
counts = accumarray(cellOf(:), 1)';
ul = ul0 + (0:M-1)*bw/1000;
dl = ul + dup;

fprintf('\nTotal duplex channels        : %d\n', M);
fprintf('Channels per cell (average)  : %.2f\n', M/N);
fprintf('Frequency reuse factor       : 1/%d\n\n', N);
for k = 1:N
    ch = find(cellOf == k);
    fprintf('Cell group %2d: %3d channels | first channels %s | UL %.1f MHz / DL %.1f MHz (first)\n', ...
        k, numel(ch), mat2str(ch(1:min(6, numel(ch)))), ul(ch(1)), dl(ch(1)));
end

cmap = hsv(N)*0.75 + 0.25;

figure('Color', 'w', 'Position', [80 80 1100 750]);

subplot(2,2,1);
scatter(ul, cellOf, 22, cmap(cellOf, :), 'filled');
grid on; yticks(1:N);
xlabel('Uplink frequency (MHz)'); ylabel('Cell group');
title('Channel assignment per cell group');

subplot(2,2,2);
b = bar(counts);
b.FaceColor = 'flat';
b.CData = cmap;
grid on;
xlabel('Cell group'); ylabel('Number of channels');
title('Channels allocated per cell');

subplot(2,2,3);
K = ceil(sqrt(N)) + 2;
[q, r] = meshgrid(-K:K);
keep = abs(q + r) <= K;
q = q(keep); r = r(keep);
x = sqrt(3)*(q + r/2);
y = 1.5*r;
sN = (ni + nj)*q + nj*r;
tN = -nj*q + ni*r;
[~, ~, id] = unique([mod(sN, N) mod(tN, N)], 'rows');
hexcells(x, y, 1, cmap(id, :), 0.5);
hold on;
for k = 1:numel(id)
    text(x(k), y(k), num2str(id(k)), 'HorizontalAlignment', 'center', 'FontSize', 8);
end
axis equal off;
title(sprintf('Frequency reuse pattern (N = %d)', N));

subplot(2,2,4);
scatter([ul dl], [ones(1, M) 2*ones(1, M)], 20, [cmap(cellOf, :); cmap(cellOf, :)], 's', 'filled');
yticks([1 2]); yticklabels({'Uplink', 'Downlink'}); ylim([0.5 2.5]);
grid on;
xlabel('Frequency (MHz)');
title('Uplink / downlink channel map');

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
