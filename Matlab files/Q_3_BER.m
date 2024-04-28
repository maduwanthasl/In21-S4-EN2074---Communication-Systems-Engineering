%Task 3: Designing a zero-forcing (ZF) equalizer for a 3-tap multipath channel

seqLen = 10^6; % Length of the binary sequence
ebN0dBVals = 0:10; % multiple Eb/N0 values
numTaps = 4;
errCounts = zeros(numTaps, length(ebN0dBVals)); % Initialize error count

for idx_ebN0 = 1:length(ebN0dBVals)
    
    % Transmitter
    inputSeq = rand(1, seqLen) > 0.5; % Generating a random binary sequence
    modSignal = 2 * inputSeq - 1; % BPSK modulation 0 -> -1; 1 -> +1
    
    % Channel model, multipath channel
    numPaths = 3;
    channelResp = [0.3 0.9 0.4];
    
    channelOut = conv(modSignal, channelResp);
    noiseVec = 1/sqrt(2) * [randn(1, seqLen + length(channelResp) - 1) + 1j * randn(1, seqLen + length(channelResp) - 1)]; % White Gaussian noise, 0dB variance
    
    % Noise addition
    receivedSignal = channelOut + 10^(-ebN0dBVals(idx_ebN0) / 20) * noiseVec; % Additive white Gaussian noise
    
    for idx_tap = 1:numTaps
        respLen = length(channelResp);
        hMat = toeplitz([channelResp(2:end), zeros(1, 2 * idx_tap + 1 - respLen + 1)], [channelResp(2:-1:1), zeros(1, 2 * idx_tap + 1 - respLen + 1)]);
        
        diracSeq = zeros(1, 2 * idx_tap + 1);
        diracSeq(idx_tap + 1) = 1;
        
        coeff = inv(hMat) * diracSeq.';
        
        % Matched filter
        filtSignal = conv(receivedSignal, coeff);
        filtSignal = filtSignal(idx_tap + 2:end);
        filtSignal = conv(filtSignal, ones(1, 1)); % Convolution
        sampledSig = filtSignal(1:1:seqLen); % Sampling at time T
        
        % Receiver - hard decision decoding
        decodedSeq = real(sampledSig) > 0;
        
        % Counting the errors
        errCounts(idx_tap, idx_ebN0) = sum(inputSeq ~= decodedSeq);
    end
end

simBER = errCounts / seqLen; % Simulated BER
theoryBER = 0.5 * erfc(sqrt(10.^(ebN0dBVals / 10))); % Theoretical BER

% Plot
close all
figure
semilogy(ebN0dBVals, simBER(1,:), 'bs-', 'Linewidth',2);
hold on
semilogy(ebN0dBVals, simBER(2,:), 'gd-', 'Linewidth',2);
semilogy(ebN0dBVals, simBER(3,:), 'ks-', 'Linewidth',2);
semilogy(ebN0dBVals, simBER(4,:), 'mx-', 'Linewidth',2);
semilogy(ebN0dBVals, theoryBER, 'ro-', 'Linewidth',2);
axis([0 10 10^-3 0.5])
grid on

%legend('sim-3tap', 'sim-5tap', 'sim-7tap', 'sim-9tap');
legend('sim-3tap', 'sim-5tap', 'sim-7tap', 'sim-9tap','AWGN Channel');
xlabel('Eb/No, dB');
ylabel('Bit Error Rate');
title('Bit error probability curve for BPSK in ISI with ZF equalizer');
