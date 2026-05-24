import os
import wave
import numpy as np

workspace_dir = r"f:\OneDrive - NTiC GmbH\Dokumente\GitHub\intercable-connectris"
audio_dir = os.path.join(workspace_dir, "assets", "audio")

os.makedirs(audio_dir, exist_ok=True)

def save_wav(filename, samples, sample_rate=44100):
    # normalize and prevent division by zero
    max_val = np.max(np.abs(samples))
    if max_val > 0:
        samples = samples / max_val
    samples = np.int16(samples * 32767)
    path = os.path.join(audio_dir, filename)
    with wave.open(path, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(samples.tobytes())

sr = 44100

# 1. pressen.wav
t = np.linspace(0, 0.5, int(sr * 0.5), False)
pressen = np.sin(2 * np.pi * 50 * t) * np.exp(-5 * t)
noise = np.random.normal(0, 0.1, len(t)) * np.exp(-10 * t)
save_wav("pressen.wav", pressen + noise)

# 2. laser_zischen.wav
t = np.linspace(0, 0.8, int(sr * 0.8), False)
laser = np.sin(2 * np.pi * (1000 - 800 * t) * t) * np.exp(-3 * t)
save_wav("laser_zischen.wav", laser)

# 3. schneiden.wav
t = np.linspace(0, 0.2, int(sr * 0.2), False)
schneiden = np.random.normal(0, 1, len(t)) * np.exp(-20 * t)
save_wav("schneiden.wav", schneiden)

# 4. menu_klick.wav
t = np.linspace(0, 0.1, int(sr * 0.1), False)
klick = np.sin(2 * np.pi * 600 * t) * np.exp(-30 * t)
save_wav("menu_klick.wav", klick)

print("Audio generated in", audio_dir)
