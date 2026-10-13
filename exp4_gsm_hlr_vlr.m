clear; clc; close all;
rng(7);

nLA = round(ask('Number of location areas', 3));
nSub = round(ask('Number of subscribers', 4));
laInit = ask('Initial LA of each subscriber (vector)', mod(0:nSub-1, nLA) + 1);
mover = round(ask('Index of the moving subscriber', 1));
laDest = round(ask('Destination LA of the moving subscriber', mod(laInit(mover), nLA) + 1));
callType = ask('Call after update (1 = mobile originated, 2 = mobile terminated)', 2);

if numel(laInit) ~= nSub || mover < 1 || mover > nSub || laDest < 1 || laDest > nLA
    error('Invalid subscriber or location area input');
end

imsi = arrayfun(@(k) sprintf('47001%010d', 1000 + k), 1:nSub, 'UniformOutput', false);
msisdn = arrayfun(@(k) sprintf('+88017%08d', 10000000 + 137*k), 1:nSub, 'UniformOutput', false);

serving = laInit(:)';
vlr = cell(1, nLA);
for k = 1:nSub
    vlr{serving(k)}(end+1) = k;
end

fprintf('\n===== Registers before location update =====\n');
showdb(imsi, msisdn, serving, vlr);

src = serving(mover);
dst = laDest;

if src ~= dst
    vlr{src}(vlr{src} == mover) = [];
    vlr{dst}(end+1) = mover;
    serving(mover) = dst;
    fprintf('\nMS-%d moved from LA-%d to LA-%d -> location update performed\n', mover, src, dst);
else
    fprintf('\nMS-%d stays in LA-%d -> no location update required\n', mover, src);
end

fprintf('\n===== Registers after location update =====\n');
showdb(imsi, msisdn, serving, vlr);

figure('Color', 'w', 'Position', [80 80 900 330]);
hold on;
for k = 1:nLA
    rectangle('Position', [k-1 0 1 1], 'FaceColor', [0.9 0.95 1], 'EdgeColor', 'b', 'LineWidth', 1.5);
    text(k-0.5, 1.07, sprintf('LA-%d (MSC/VLR-%d)', k, k), 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
for k = 1:nSub
    la = laInit(k);
    px = la - 0.8 + 0.6*mod(k*0.37, 1);
    py = 0.2 + 0.6*mod(k*0.61, 1);
    if k == mover
        plot(px, py, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 10);
        mx = px; my = py;
    else
        plot(px, py, 'ko', 'MarkerFaceColor', 'k');
    end
    text(px + 0.04, py + 0.05, sprintf('MS-%d', k), 'FontSize', 8);
end
if src ~= dst
    quiver(mx, my, (dst - src), 0, 0, 'r', 'LineWidth', 2, 'MaxHeadSize', 0.3);
end
axis([-0.1 nLA + 0.1 -0.1 1.2]); axis off;
title('Location area layout and subscriber movement');

if src ~= dst
    ents = {'MS', 'BTS/BSC', sprintf('MSC/VLR-%d (new)', dst), 'HLR', sprintf('MSC/VLR-%d (old)', src)};
    m = {
        1 2 'Channel Request (RACH)'
        2 1 'Immediate Assignment (AGCH)'
        1 3 'Location Updating Request (IMSI/TMSI, old LAI)'
        3 5 'Send Identification (old TMSI)'
        5 3 'Identification Response (IMSI, auth sets)'
        3 1 'Authentication Request (RAND)'
        1 3 'Authentication Response (SRES)'
        3 4 'Update Location (IMSI, new VLR no.)'
        4 5 'Cancel Location (IMSI)'
        5 4 'Cancel Location Ack'
        4 3 'Insert Subscriber Data (profile)'
        3 4 'Insert Subscriber Data Ack'
        4 3 'Update Location Ack'
        3 1 'Location Updating Accept (new TMSI)'
        1 3 'TMSI Reallocation Complete'
        3 1 'Channel Release'
    };
    drawseq(ents, m, sprintf('GSM location update: MS-%d, LA-%d to LA-%d', mover, src, dst));
end

if callType == 1
    ents = {'MS', 'BTS/BSC', sprintf('MSC/VLR-%d', dst), 'GMSC/PSTN', 'Called party'};
    m = {
        1 2 'Channel Request (RACH)'
        2 1 'Immediate Assignment (AGCH)'
        1 3 'CM Service Request'
        3 1 'Authentication Request'
        1 3 'Authentication Response'
        3 1 'Ciphering Mode Command'
        1 3 'Setup (called number)'
        3 1 'Call Proceeding'
        3 2 'Assignment Request (TCH)'
        2 3 'Assignment Complete'
        3 4 'IAM (ISUP)'
        4 5 'Ringing the called party'
        4 3 'ACM (address complete)'
        3 1 'Alerting (ringback)'
        5 4 'Called party answers'
        4 3 'ANM (answer)'
        3 1 'Connect'
        1 3 'Connect Acknowledge'
    };
    drawseq(ents, m, sprintf('GSM mobile-originated call setup: MS-%d', mover));
else
    ents = {'Calling party', 'GMSC', 'HLR', sprintf('MSC/VLR-%d', dst), 'BTS/BSC', 'MS'};
    m = {
        1 2 'IAM (dialled MSISDN)'
        2 3 'Send Routing Information (MSISDN)'
        3 4 'Provide Roaming Number (IMSI)'
        4 3 'MSRN'
        3 2 'Routing Information (MSRN)'
        2 4 'IAM (MSRN)'
        4 5 'Paging (all cells of LA)'
        5 6 'Paging Request (PCH)'
        6 5 'Channel Request (RACH)'
        5 6 'Immediate Assignment (AGCH)'
        6 4 'Paging Response'
        4 6 'Authentication / Ciphering'
        4 6 'Setup'
        6 4 'Call Confirmed'
        4 5 'Assignment Request (TCH)'
        5 4 'Assignment Complete'
        6 4 'Alerting'
        4 2 'ACM'
        2 1 'ACM (ringback to caller)'
        6 4 'Connect (user answers)'
        4 2 'ANM'
        2 1 'ANM'
    };
    drawseq(ents, m, sprintf('GSM mobile-terminated call setup: MS-%d', mover));
end

function showdb(imsi, msisdn, serving, vlr)
nSub = numel(imsi);
T = table((1:nSub)', imsi(:), msisdn(:), serving(:), 'VariableNames', {'MS', 'IMSI', 'MSISDN', 'VLR_LA'});
disp('HLR:');
disp(T);
for k = 1:numel(vlr)
    if isempty(vlr{k})
        s = '(empty)';
    else
        s = strjoin(arrayfun(@(u) sprintf('MS-%d', u), vlr{k}, 'UniformOutput', false), ', ');
    end
    fprintf('VLR-%d: %s\n', k, s);
end
end

function drawseq(ents, m, ttl)
n = numel(ents);
k = size(m, 1);
figure('Color', 'w', 'Position', [60 40 150*n + 150 34*k + 140]);
hold on;
for e = 1:n
    plot([e e], [0 -(k + 1)], 'Color', [0.6 0.6 0.6], 'LineStyle', '--');
    text(e, 0.45, ents{e}, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9);
end
for j = 1:k
    x1 = m{j, 1}; x2 = m{j, 2}; y = -j;
    s = sign(x2 - x1);
    plot([x1 x2], [y y], 'k', 'LineWidth', 1.1);
    patch([x2 x2 - s*0.1 x2 - s*0.1], [y y + 0.18 y - 0.18], 'k');
    text((x1 + x2)/2, y + 0.3, sprintf('%d. %s', j, m{j, 3}), 'HorizontalAlignment', 'center', 'FontSize', 8);
end
axis([0.4 n + 0.6 -(k + 1) 1]); axis off;
title(ttl);
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
