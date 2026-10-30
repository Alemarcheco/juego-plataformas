"""Genera la música y los efectos de sonido del juego (estilo 8 bits).

Uso: python3 tools/sonidos.py   (necesita numpy y ffmpeg)
Escribe los .ogg en assets/audio/.
"""
import os
import random
import subprocess
import tempfile
import wave

import numpy as np

SR = 22050
SALIDA = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')

NOTAS = {'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5, 'F#': 6, 'G': 7,
         'G#': 8, 'A': 9, 'A#': 10, 'B': 11}
ESCALAS = {
    'mayor': [0, 2, 4, 5, 7, 9, 11],
    'menor': [0, 2, 3, 5, 7, 8, 10],
    'armonica': [0, 2, 3, 5, 7, 8, 11],
    'frigia_dom': [0, 1, 4, 5, 7, 8, 10],
    'lidia': [0, 2, 4, 6, 7, 9, 11],
    'dorica': [0, 2, 3, 5, 7, 9, 10],
}


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


# ------------------------------------------------------------ instrumentos
def onda(tipo, f, n, ancho=0.5):
    t = np.arange(n) / SR
    fase = (f * t) % 1.0
    if tipo == 'cuadrada':
        return np.where(fase < ancho, 1.0, -1.0)
    if tipo == 'triangulo':
        return 4 * np.abs(fase - 0.5) - 1
    if tipo == 'sierra':
        return 2 * fase - 1
    if tipo == 'seno':
        return np.sin(2 * np.pi * f * t)
    if tipo == 'campana':
        return np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2.76 * t)
    raise ValueError(tipo)


def envolvente(n, ataque=0.005, caida=0.08, sostener=0.6, soltar=0.05):
    e = np.ones(n) * sostener
    a = max(1, int(ataque * SR))
    d = max(1, int(caida * SR))
    r = max(1, int(soltar * SR))
    a = min(a, n)
    e[:a] = np.linspace(0, 1, a)
    fin_d = min(n, a + d)
    e[a:fin_d] = np.linspace(1, sostener, fin_d - a)
    r = min(r, n)
    e[n - r:] *= np.linspace(1, 0, r)
    return e


def nota(tipo, midi, dur, vol=0.3, ancho=0.5, sostener=0.6, caida=0.08, vibrato=0.0):
    n = int(dur * SR)
    f = hz(midi)
    if vibrato:
        t = np.arange(n) / SR
        f = f * (1 + vibrato * np.sin(2 * np.pi * 5.5 * t) * np.clip(t * 4, 0, 1))
        fase = np.cumsum(f) / SR
        if tipo == 'seno':
            s = np.sin(2 * np.pi * fase)
        elif tipo == 'triangulo':
            s = 4 * np.abs(fase % 1 - 0.5) - 1
        else:
            s = np.where(fase % 1 < ancho, 1.0, -1.0)
    else:
        s = onda(tipo, f, n, ancho)
    caida_c = 0.6 if tipo == 'campana' else caida
    sost = 0.0 if tipo == 'campana' else sostener
    return s * envolvente(n, caida=caida_c, sostener=sost) * vol


def bombo(vol=0.6):
    n = int(0.18 * SR)
    t = np.arange(n) / SR
    f = 120 * np.exp(-t * 25) + 40
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 18) * vol


def caja(vol=0.35, rnd=None):
    n = int(0.14 * SR)
    t = np.arange(n) / SR
    ruido = (rnd or np.random).uniform(-1, 1, n)
    return (ruido * 0.8 + np.sin(2 * np.pi * 190 * t) * 0.4) * np.exp(-t * 28) * vol


def platillo(vol=0.12, rnd=None):
    n = int(0.05 * SR)
    t = np.arange(n) / SR
    ruido = (rnd or np.random).uniform(-1, 1, n)
    ruido = np.diff(ruido, prepend=0)  # más agudo
    return ruido * np.exp(-t * 80) * vol


def mezclar(pista, sonido, en):
    i = int(en * SR)
    fin = min(len(pista), i + len(sonido))
    if fin > i:
        pista[i:fin] += sonido[:fin - i]


# ------------------------------------------------------------ canciones
CANCIONES = {
    # id: (tónica, escala, bpm, acordes (grados), lead, swing, batería, carácter)
    'planicie': ('C', 'mayor', 140, [0, 4, 5, 3], ('cuadrada', 0.5), 0, 'pop', 'alegre'),
    'desierto': ('D', 'frigia_dom', 118, [0, 1, 0, 6], ('cuadrada', 0.25), 0, 'tambor', 'misterio'),
    'mar': ('F', 'mayor', 92, [0, 5, 3, 4], ('seno', 0.5), 0, 'suave', 'calma'),
    'cielo': ('G', 'lidia', 112, [0, 1, 0, 4], ('triangulo', 0.5), 0, 'suave', 'alegre'),
    'nieve': ('E', 'menor', 100, [0, 5, 3, 6], ('campana', 0.5), 0, 'suave', 'calma'),
    'ciudad': ('A', 'menor', 128, [0, 5, 2, 6], ('sierra', 0.5), 0, 'disco', 'energia'),
    'lava': ('C', 'menor', 150, [0, 0, 5, 6], ('cuadrada', 0.25), 0, 'rock', 'energia'),
    'veneno': ('A#', 'dorica', 104, [0, 3, 0, 4], ('cuadrada', 0.125), 0.33, 'tambor', 'misterio'),
    'caja': ('C', 'mayor', 132, [0, 3, 4, 0], ('cuadrada', 0.125), 0, 'pop', 'saltarin'),
    'bosque': ('D', 'menor', 84, [0, 5, 6, 4], ('triangulo', 0.5), 0, 'suave', 'misterio'),
    'castillo': ('A', 'armonica', 120, [0, 5, 3, 4], ('cuadrada', 0.5), 0, 'rock', 'misterio'),
    'jefe': ('E', 'armonica', 165, [0, 5, 3, 4], ('cuadrada', 0.25), 0, 'rock', 'energia'),
    'secreto': ('F', 'mayor', 116, [0, 2, 3, 4], ('campana', 0.5), 0.33, 'pop', 'saltarin'),
}


def acorde(escala, grado):
    """Notas (en semitonos sobre la tónica) del acorde de tres notas del grado."""
    return [escala[(grado + k) % 7] + 12 * ((grado + k) // 7) for k in (0, 2, 4)]


RITMOS = {
    'alegre': [[1, 1, 2, 1, 1, 2], [2, 1, 1, 2, 2], [1, 1, 1, 1, 2, 2]],
    'calma': [[4, 2, 2], [2, 2, 4], [3, 1, 4]],
    'misterio': [[3, 1, 2, 2], [2, 2, 1, 1, 2], [4, 4]],
    'energia': [[1, 1, 1, 1, 1, 1, 2], [2, 1, 1, 2, 1, 1], [1, 1, 2, 1, 1, 2]],
    'saltarin': [[1, 1, 1, 1, 2, 2], [1, 2, 1, 2, 2], [2, 1, 1, 1, 1, 2]],
}


def motivo(rnd, escala, grados, caracter):
    """Melodía de 2 compases (en corcheas) sobre dos acordes."""
    notas = []
    for g in grados:
        ac = acorde(escala, g)
        ritmo = rnd.choice(RITMOS[caracter])
        anterior = None
        for k, dur in enumerate(ritmo):
            if k == 0 or rnd.random() < 0.6:
                n = rnd.choice(ac)
            else:
                # nota de paso de la escala cerca de la anterior
                base = anterior if anterior is not None else ac[0]
                idx = min(range(7), key=lambda i: abs(escala[i] - base % 12))
                n = escala[(idx + rnd.choice([-1, 1])) % 7] + (base // 12) * 12
            if rnd.random() < 0.3:
                n += 12
            if rnd.random() < 0.12 and k > 0:
                n = None  # silencio
            notas.append((n, dur))
            if n is not None:
                anterior = n
    return notas


def cancion(nombre):
    tonica, esc, bpm, grados, (lead, ancho), swing, bateria, caracter = CANCIONES[nombre]
    rnd = random.Random(nombre)
    ruido = np.random.RandomState(sum(map(ord, nombre)))
    escala = ESCALAS[esc]
    base = 60 + NOTAS[tonica]
    if base > 64:
        base -= 12
    negra = 60 / bpm
    corchea = negra / 2
    compas = negra * 4
    compases = 16
    total = compases * compas
    pista = np.zeros(int(total * SR) + SR)

    # Melodía con forma A A B A
    a1 = motivo(rnd, escala, grados[:2], caracter)
    a2 = motivo(rnd, escala, grados[2:], caracter)
    b1 = motivo(rnd, escala, grados[:2], caracter)
    b2 = motivo(rnd, escala, grados[2:], caracter)
    forma = [a1, a2, a1, a2, b1, b2, a1, a2]
    t = 0.0
    vol_lead = {'sierra': 0.11, 'cuadrada': 0.12, 'triangulo': 0.24, 'seno': 0.26, 'campana': 0.2}[lead]
    for frase in forma:
        for n, dur in frase:
            d = dur * corchea
            if n is not None:
                s = nota(lead, base + 12 + n, d * 0.92, vol_lead, ancho,
                         vibrato=0.006 if lead in ('seno', 'triangulo') else 0)
                inicio = t + (corchea * swing if swing and (round(t / corchea) % 2 == 1) else 0)
                mezclar(pista, s, inicio)
            t += d

    # Bajo y arpegios: un acorde por compás
    for c in range(compases):
        g = grados[c % 4]
        ac = acorde(escala, g)
        raiz = base - 12 + ac[0]
        t0 = c * compas
        patron = {'pop': [0, 0, 7, 0], 'rock': [0, 0, 0, 0, 0, 0, 0, 0],
                  'disco': [0, 12, 0, 12, 0, 12, 0, 12], 'suave': [0, 7],
                  'tambor': [0, 0, 7, 0]}[bateria]
        paso = compas / len(patron)
        for k, p in enumerate(patron):
            mezclar(pista, nota('triangulo', raiz + p, paso * 0.85, 0.3, caida=0.05, sostener=0.8), t0 + k * paso)
        # arpegio suave
        if bateria in ('suave', 'pop', 'tambor'):
            arp = [ac[0], ac[1], ac[2], ac[1]] * 2
            for k, n in enumerate(arp):
                mezclar(pista, nota('cuadrada', base + n, corchea * 0.6, 0.035, 0.25, sostener=0.2),
                        t0 + k * corchea)
        else:
            for k in range(8):
                if k % 2 == 1:
                    for n in ac:
                        mezclar(pista, nota('cuadrada', base + n, corchea * 0.4, 0.025, 0.5, sostener=0.3),
                                t0 + k * corchea)

    # Batería
    for c in range(compases):
        t0 = c * compas
        for k in range(8):
            tk = t0 + k * corchea
            if bateria == 'suave':
                if k == 0:
                    mezclar(pista, bombo(0.25), tk)
                if k % 2 == 1:
                    mezclar(pista, platillo(0.04, ruido), tk)
                continue
            if bateria == 'tambor':
                if k in (0, 3, 6):
                    mezclar(pista, bombo(0.45), tk)
                if k in (2, 7):
                    mezclar(pista, caja(0.16, ruido), tk)
                continue
            if bateria == 'disco':
                if k % 2 == 0:
                    mezclar(pista, bombo(0.5), tk)
                if k in (2, 6):
                    mezclar(pista, caja(0.22, ruido), tk)
                if k % 2 == 1:
                    mezclar(pista, platillo(0.12, ruido), tk)
                continue
            # pop y rock
            if k in (0, 4) or (bateria == 'rock' and k in (3, 5)):
                mezclar(pista, bombo(0.5), tk)
            if k in (2, 6):
                mezclar(pista, caja(0.25, ruido), tk)
            mezclar(pista, platillo(0.07, ruido), tk)

    pista = pista[:int(total * SR)]
    return pista


# ------------------------------------------------------------ efectos
def barrido(f0, f1, dur, tipo='cuadrada', vol=0.4, ancho=0.5, curva=1.0):
    n = int(dur * SR)
    t = np.linspace(0, 1, n)
    f = f0 + (f1 - f0) * t ** curva
    fase = np.cumsum(f) / SR
    if tipo == 'cuadrada':
        s = np.where(fase % 1 < ancho, 1.0, -1.0)
    elif tipo == 'triangulo':
        s = 4 * np.abs(fase % 1 - 0.5) - 1
    else:
        s = np.sin(2 * np.pi * fase)
    return s * envolvente(n, 0.002, dur * 0.3, 0.7, dur * 0.4) * vol


def secuencia(notas, dur, tipo='cuadrada', vol=0.35, ancho=0.5):
    # 0 es un silencio
    partes = [nota(tipo, m, dur, vol, ancho, sostener=0.7, caida=0.03) if m else np.zeros(int(dur * SR))
              for m in notas]
    return np.concatenate(partes)


def explosion(dur=0.45, vol=0.6):
    n = int(dur * SR)
    t = np.arange(n) / SR
    r = np.random.RandomState(7).uniform(-1, 1, n)
    # ruido que se va haciendo grave
    s = np.zeros(n)
    acc = 0.0
    for i in range(n):
        k = 0.05 + 0.6 * (1 - i / n)
        acc += (r[i] - acc) * k
        s[i] = acc
    return s * np.exp(-t * 6) * vol * 2


EFECTOS = {
    'salto': lambda: barrido(300, 700, 0.14, 'cuadrada', 0.25, 0.25),
    'nadar': lambda: barrido(400, 600, 0.12, 'seno', 0.3),
    'pescado': lambda: secuencia([88, 95], 0.06, 'cuadrada', 0.22, 0.5),
    'corazon': lambda: secuencia([72, 76, 79, 84], 0.07, 'triangulo', 0.4),
    'pisar': lambda: barrido(500, 120, 0.12, 'cuadrada', 0.35, 0.5, 0.6),
    'herido': lambda: barrido(400, 150, 0.25, 'cuadrada', 0.35, 0.5),
    'morir': lambda: secuencia([72, 71, 70, 69, 64, 60, 55], 0.09, 'cuadrada', 0.3),
    'ganar': lambda: secuencia([60, 64, 67, 72, 67, 72, 76, 79, 84], 0.09, 'cuadrada', 0.28, 0.25),
    'golpe_jefe': lambda: np.concatenate([barrido(200, 60, 0.12, 'cuadrada', 0.45), explosion(0.15, 0.3)]),
    'explosion': lambda: explosion(0.45, 0.6),
    'lanzar': lambda: barrido(900, 300, 0.1, 'triangulo', 0.25),
    'aviso': lambda: secuencia([81, 0, 81], 0.05, 'cuadrada', 0.15, 0.5),
    'logro': lambda: secuencia([72, 76, 79, 84, 0, 79, 84], 0.1, 'triangulo', 0.45),
    'portal': lambda: barrido(200, 1500, 0.8, 'seno', 0.35, curva=2),
    'bandera': lambda: secuencia([67, 72, 76], 0.08, 'triangulo', 0.4),
}


# ------------------------------------------------------------ guardar
def guardar_ogg(datos, nombre, calidad=3):
    datos = datos / max(1e-6, np.max(np.abs(datos))) * 0.85
    pcm = (datos * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
        ruta = tmp.name
    with wave.open(ruta, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    destino = os.path.join(SALIDA, nombre + '.ogg')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', ruta, '-c:a', 'libvorbis',
                    '-q:a', str(calidad), destino], check=True)
    os.remove(ruta)


def main():
    os.makedirs(SALIDA, exist_ok=True)
    for nombre in CANCIONES:
        guardar_ogg(cancion(nombre), 'musica_' + nombre)
        print('música', nombre)
    for nombre, hacer in EFECTOS.items():
        guardar_ogg(hacer(), 'efecto_' + nombre, calidad=4)
        print('efecto', nombre)


if __name__ == '__main__':
    main()
