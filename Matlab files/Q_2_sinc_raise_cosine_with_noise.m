% Defining the system Parameters
BitCount = 10^3; % Number of Bits Transmitted
SamplingFrequency = 10; % Sampling frequency in Hz
SNR_dB = 10;
NoisePower = 1./(10.^(0.1*SNR_dB)); % Noise Power (Eb = 1 in BPSK)
time = -SamplingFrequency:1/SamplingFrequency:SamplingFrequency; % Time Array

%% Generating the BPSK Signal
% Mapping 0 -> -1 and 1 -> 1 (0 phase and 180 phase)
BPSK_Sig = 2*(rand(1,BitCount)>0.5)-1;
t = 0:1/SamplingFrequency:99/SamplingFrequency;
stem(t, BPSK_Sig(1:100)); xlabel('Time'); ylabel('Amplitude');
title('BPSK Impulse Train');
axis([0 10 -1.2 1.2]); grid on;

%% Upsampling the transmit sequence without noise
BPSK_Upsampled = [BPSK_Sig;zeros(SamplingFrequency-1,length(BPSK_Sig))]; % Upsampling the BPSK to match the sampling frequency
BPSK_U = BPSK_Upsampled(:).';
figure;
stem(t, BPSK_U(1:100)); xlabel('Time'); ylabel('Amplitude');
title('Upsampled BPSK Impulse Train');
axis([0 10 -1.2 1.2]); grid on;

%% sinc pulse shaping filter 
Sinc_Num = sin(pi*time); % Numerator of the sinc function
Sinc_Den = (pi*time); % Denominator of the sinc function
Sinc_DenZero = find(abs(Sinc_Den) < 10^-10); % Finding the t=0 position
Sinc_Filt = Sinc_Num./Sinc_Den;
Sinc_Filt(Sinc_DenZero) = 1; % Defining the t=0 value
figure;
plot(time, Sinc_Filt);
title('Sinc Pulse shape');
xlabel('Time'); ylabel('Amplitude');
axis([-SamplingFrequency SamplingFrequency -0.5 1.2]); grid on

Conv_sinc_pulse = conv(BPSK_U, Sinc_Filt);
Conv_sinc_pulse = Conv_sinc_pulse(1:10000);
Conv_sinc_pulse_reshape = reshape(Conv_sinc_pulse, SamplingFrequency*2, BitCount*SamplingFrequency/20).';

transmit_signal_sinc = Conv_sinc_pulse(1,100:999);
tt=(-0.1:0.1:89.8);
plot(tt,transmit_signal_sinc);
title('Transmit signal with sinc pulse');

figure;
plot(0:1/SamplingFrequency:1.99, real(Conv_sinc_pulse_reshape).', 'b');
title('Eye diagram with sinc pulse');
xlabel('Time'); ylabel('Amplitude');
axis([0 2 -2.4 2.2]);
grid on

%% Raised cosine pulse shaping filter (gamma = 0.5)
roll_off = 0.5;
cos_Num = cos(roll_off*pi*time);
cos_Den = (1 - (2 * roll_off * time).^2);
cos_DenZero = abs(cos_Den)<10^-10;
RaisedCosine = cos_Num./cos_Den;
RaisedCosine(cos_DenZero) = pi/4;
RC_gamma5 = Sinc_Filt.*RaisedCosine; % Getting the complete raised cosine pulse
figure;
plot(time, RC_gamma5);
title('Raised Cosine Pulse shape gamma = 0.5');
xlabel('Time'); ylabel('Amplitude');
axis([-SamplingFrequency SamplingFrequency -0.5 1.2]); grid on

Conv_RC_gamma5 = conv(BPSK_U,RC_gamma5);
Conv_RC_gamma5 = Conv_RC_gamma5(1:10000);
Conv_RC_gamma5_reshape = reshape(Conv_RC_gamma5,SamplingFrequency*2,BitCount*SamplingFrequency/20).';

transmit_signal_RC_gamma5 = Conv_RC_gamma5(1,100:999);
tt=(-0.1:0.1:89.8);
plot(tt,transmit_signal_RC_gamma5);
title('Transmit signal with gamma = 0.5');

figure;
plot(0:1/SamplingFrequency:1.99, Conv_RC_gamma5_reshape.','b');
title('Eye diagram with gamma = 0.5');
xlabel('Time'); ylabel('Amplitude');
axis([0 2 -2.5 2.5]);
grid on

%% Raised cosine pulse shaping filter (gamma = 1)
roll_off = 1;
cos_Num = cos(roll_off * pi * time);
cos_Den = (1-(2 * roll_off * time).^2);
cos_DenZero = find(abs(cos_Den)<10^-20);
RaisedCosine = cos_Num./cos_Den;
RaisedCosine(cos_DenZero) = pi/4;
RC_gamma1 = Sinc_Filt.*RaisedCosine; % Getting the complete raised cosine pulse
figure;
plot(time, RC_gamma1);
title('Raised Cosine Pulse shape gamma = 1');
xlabel('Time'); ylabel('Amplitude');
axis([-SamplingFrequency SamplingFrequency -0.5 1.2]); grid on

Conv_RC_gamma1 = conv(BPSK_U,RC_gamma1);
Conv_RC_gamma1 = Conv_RC_gamma1(1:10000);
Conv_RC_gamma1_reshape = reshape(Conv_RC_gamma1,SamplingFrequency*2,BitCount*SamplingFrequency/20).';

transmit_signal_RC_gamma1 = Conv_RC_gamma1(1,100:999);
tt=(-0.1:0.1:89.8);
plot(tt,transmit_signal_RC_gamma1);
title('Transmit signal with gamma = 1');

figure;
plot(0:1/SamplingFrequency:1.99, Conv_RC_gamma1_reshape.','b');
title('Eye diagram with gamma = 1');
xlabel('Time'); ylabel('Amplitude');
axis([0 2 -1.5 1.5 ]);
grid on


%% Noise Array Generation based on SNR = 10dB
Noise1D = normrnd (0 , sqrt(NoisePower/2), [1, BitCount]);
AWGN_TX = BPSK_Sig + Noise1D;
figure;
stem(t, AWGN_TX(1:100)); xlabel('Time'); ylabel('Amplitude');
title('BPSK signal After adding noise');
axis([0 10 -1.5 1.5]); grid on;


%% upsampling the transmit sequence with Noise
AWGNTx_Upsample = [AWGN_TX;zeros(SamplingFrequency-1,length(BPSK_Sig))];
AWGNTx_U = AWGNTx_Upsample(:);
figure;
stem(t, AWGNTx_U(1:100)); xlabel('Time'); ylabel('Amplitude');
title('Upsampled BPSK After adding noise');
axis([0 10 -1.5 1.5]); grid on;

%% sinc with noise
Conv_sinc_noise = conv(AWGNTx_U,Sinc_Filt);
Conv_sinc_noise = Conv_sinc_noise(1:10000);
Conv_sinc_noise_reshape = reshape(Conv_sinc_noise, SamplingFrequency*2, BitCount*SamplingFrequency/20).';
figure;
plot(0:1/SamplingFrequency:1.99, Conv_sinc_noise_reshape.', 'b');
title('Eye diagram with sinc pulse After adding noise');
xlabel('Time'); ylabel('Amplitude');
axis([0 2 -2.4 2.2]);
grid on

%% raised cosine with noise (gamma = 0.5)
Conv_RC5_noise = conv(AWGNTx_U,RC_gamma5);
Conv_RC5_noise = Conv_RC5_noise(1:10000);
Conv_RC5_noise_reshape = reshape(Conv_RC5_noise,SamplingFrequency*2,BitCount*SamplingFrequency/20).';
figure;
plot(0:1/SamplingFrequency:1.99, Conv_RC5_noise_reshape.', 'b');
title('Eye diagram with gamma = 0.5 After adding noise');
xlabel('Time'); ylabel('Amplitude');
axis([0 2 -2.4 2.2]);
grid on

%% raised cosine with noise (gamma = 1)
Conv_R1_noise = conv(AWGNTx_U,RC_gamma1);
Conv_R1_noise = Conv_R1_noise(1:10000);
Conv_R1_noise_reshape = reshape(Conv_R1_noise,SamplingFrequency*2,BitCount*SamplingFrequency/20).';
figure;
plot(0:1/SamplingFrequency:1.99, Conv_R1_noise_reshape.', 'b');
title('Eye diagram with gamma = 1.0 After adding noise');
xlabel('Time'); ylabel('Amplitude');
axis([0 2 -2.4 2.2]);
grid on
