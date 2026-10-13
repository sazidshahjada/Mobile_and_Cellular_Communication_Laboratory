clear; clc; close all;

C = round(ask('Traffic channels per cell', 20));
U = ask('Number of subscribers per cell', 400);
lam = ask('Call rate per subscriber (calls/hour)', 1);
h = ask('Average call holding time (s)', 120);
gos = ask('Target grade of service (blocking probability)', 0.02);
nCalls = round(ask('Number of calls for the simulation', 1e5));
seed = ask('Random seed', 1);

rng(seed);

Au = lam*h/3600;
A = U*Au;
Pb = erlangb(A, C);
carried = A*(1 - Pb);
util = carried/C;
blockedPerHour = U*lam*Pb;
Cneed = chreq(A, gos);
Amax = maxtraffic(C, gos);
Umax = floor(Amax/Au);

lamTot = A/h;
arr = cumsum(-log(rand(nCalls, 1))/lamTot);
hold_t = -log(rand(nCalls, 1))*h;
endt = zeros(1, C);
blocked = 0;
for k = 1:nCalls
    f = find(endt <= arr(k), 1);
    if isempty(f)
        blocked = blocked + 1;
    else
        endt(f) = arr(k) + hold_t(k);
    end
end
Psim = blocked/nCalls;

fprintf('\nTraffic per user                   : %.4f Erlang\n', Au);
fprintf('Total offered traffic A            : %.3f Erlang\n', A);
fprintf('Blocking probability (Erlang-B)    : %.4f\n', Pb);
fprintf('Blocking probability (simulation)  : %.4f\n', Psim);
fprintf('Carried traffic                    : %.3f Erlang\n', carried);
fprintf('Channel utilisation                : %.2f %%\n', 100*util);
fprintf('Blocked calls per hour             : %.2f\n', blockedPerHour);
fprintf('Channels needed for GoS = %.3f     : %d\n', gos, Cneed);
fprintf('Max traffic for %d channels at GoS : %.3f Erlang\n', C, Amax);
fprintf('Max subscribers at that GoS        : %d\n', Umax);

figure('Color', 'w', 'Position', [80 60 1100 800]);

subplot(2,2,1);
Ar = linspace(0.01, max(60, 1.5*A), 600);
hold on;
for c = unique([5 10 20 30 40 50 C])
    semilogy(Ar, erlangb(Ar, c), 'LineWidth', 1.3, 'DisplayName', sprintf('C = %d', c));
end
set(gca, 'YScale', 'log');
plot(A, Pb, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 8, 'DisplayName', 'Operating point');
plot(A, max(Psim, 1e-4), 'rx', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Simulation');
plot([Ar(1) Ar(end)], [gos gos], 'k--', 'DisplayName', 'Target GoS');
ylim([1e-4 1]); grid on; legend('Location', 'southeast');
xlabel('Offered traffic (Erlang)'); ylabel('Blocking probability');
title('Erlang-B blocking vs offered traffic');

subplot(2,2,2);
Cr = 1:max(60, Cneed + 10);
Pc = arrayfun(@(c) erlangb(A, c), Cr);
semilogy(Cr, Pc, 'b-o', 'LineWidth', 1.3, 'MarkerSize', 4); hold on;
plot([Cr(1) Cr(end)], [gos gos], 'k--');
plot(C, Pb, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
plot(Cneed, erlangb(A, Cneed), 'gs', 'MarkerFaceColor', 'g', 'MarkerSize', 8);
ylim([1e-4 1]); grid on;
xlabel('Number of channels'); ylabel('Blocking probability');
title(sprintf('Blocking vs channels at A = %.2f Erlang', A));
legend('Blocking', 'Target GoS', 'Current C', 'Channels needed', 'Location', 'northeast');

subplot(2,2,3);
Cg = 1:60;
hold on;
for g = unique([0.01 0.02 0.05 0.1 gos])
    plot(Cg, arrayfun(@(c) maxtraffic(c, g), Cg), 'LineWidth', 1.4, 'DisplayName', sprintf('GoS = %.3g', g));
end
grid on; legend('Location', 'northwest');
xlabel('Number of channels'); ylabel('Maximum offered traffic (Erlang)');
title('Channel capacity at given grade of service');

subplot(2,2,4);
Aa = linspace(0, 2*C, 300);
plot(Aa, Aa.*(1 - erlangb(Aa, C)), 'b', 'LineWidth', 1.6, 'DisplayName', 'Carried'); hold on;
plot(Aa, Aa, 'k--', 'DisplayName', 'Offered');
plot(A, carried, 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'Operating point');
grid on; legend('Location', 'northwest');
xlabel('Offered traffic (Erlang)'); ylabel('Carried traffic (Erlang)');
title(sprintf('Carried vs offered traffic (C = %d)', C));

function B = erlangb(A, C)
B = ones(size(A));
for k = 1:C
    B = A.*B./(k + A.*B);
end
end

function Cn = chreq(A, gos)
Cn = 1;
while erlangb(A, Cn) > gos
    Cn = Cn + 1;
end
end

function A = maxtraffic(C, gos)
lo = 0;
hi = 10*C + 10;
for k = 1:60
    mid = (lo + hi)/2;
    if erlangb(mid, C) > gos
        hi = mid;
    else
        lo = mid;
    end
end
A = lo;
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
