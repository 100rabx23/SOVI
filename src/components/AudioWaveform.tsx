import React, { useEffect, useRef, useState } from 'react';

interface AudioWaveformProps {
  isTransmitting?: boolean;
  isListening?: boolean;
  audioData?: Float32Array; // Real-time audio data
}


//7766
export function AudioWaveform({ isTransmitting, isListening, audioData }: AudioWaveformProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [dimensions, setDimensions] = useState({ width: 0, height: 0 });
  
  useEffect(() => {
    if (!containerRef.current) return;
    const observer = new ResizeObserver(entries => {
      for (let entry of entries) {
        setDimensions({
          width: entry.contentRect.width,
          height: entry.contentRect.height
        });
      }
    });
    observer.observe(containerRef.current);
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || dimensions.width === 0 || dimensions.height === 0) return;
    
    // Set internal canvas resolution to match display size exactly
    const dpr = window.devicePixelRatio || 1;
    canvas.width = dimensions.width * dpr;
    canvas.height = dimensions.height * dpr;
    
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.scale(dpr, dpr);

    let animationId: number;
    let phase = 0;

    const render = () => {
      const { width, height } = dimensions;
      ctx.clearRect(0, 0, width, height);

      // If we have actual audio data (like when receiving), draw it
      if (audioData && isListening) {
        ctx.beginPath();
        ctx.strokeStyle = '#3b82f6'; // electric blue
        ctx.lineWidth = 2;
        const sliceWidth = width / audioData.length;
        let x = 0;
        for (let i = 0; i < audioData.length; i++) {
          const v = audioData[i] * 5.0; // amplify for visualization
          const y = (height / 2) + (v * height / 2);
          if (i === 0) {
            ctx.moveTo(x, y);
          } else {
            ctx.lineTo(x, y);
          }
          x += sliceWidth;
        }
        ctx.stroke();
      } else if (isTransmitting) {
        // Draw a fake sine wave animation when transmitting (since we don't capture our own output easily)
        ctx.beginPath();
        ctx.strokeStyle = '#a855f7'; // purple
        ctx.lineWidth = 3;
        for (let i = 0; i < width; i++) {
          const x = i;
          const y = (Math.sin((i * 0.05) + phase) * (height / 3)) + (height / 2);
          if (i === 0) {
            ctx.moveTo(x, y);
          } else {
            ctx.lineTo(x, y);
          }
        }
        ctx.stroke();

        // Draw secondary glowing wave
        ctx.beginPath();
        ctx.strokeStyle = 'rgba(168, 85, 247, 0.4)';
        ctx.lineWidth = 6;
        for (let i = 0; i < width; i++) {
          const x = i;
          const y = (Math.sin((i * 0.04) + phase * 1.2) * (height / 4)) + (height / 2);
          if (i === 0) {
            ctx.moveTo(x, y);
          } else {
            ctx.lineTo(x, y);
          }
        }
        ctx.stroke();
      } else {
        // Idle straight line
        ctx.beginPath();
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.1)';
        ctx.lineWidth = 2;
        ctx.moveTo(0, height / 2);
        ctx.lineTo(width, height / 2);
        ctx.stroke();
      }

      phase += 0.15;
      animationId = requestAnimationFrame(render);
    };

    render();

    return () => {
      cancelAnimationFrame(animationId);
    };
  }, [isTransmitting, isListening, audioData, dimensions]);

  return (
    <div ref={containerRef} className="w-full h-full min-h-[120px] bg-white/[0.03] border border-white/5 rounded-3xl overflow-hidden backdrop-blur-xl p-4 flex items-center justify-center relative">
      <canvas
        ref={canvasRef}
        style={{ width: dimensions.width, height: dimensions.height }}
        className="block"
      />
      {(isTransmitting || isListening) && (
        <div className="absolute top-4 left-5 flex items-center space-x-2">
          <div className={`w-2 h-2 rounded-full animate-pulse ${isTransmitting ? 'bg-purple-500' : 'bg-blue-500'}`}></div>
          <span className="text-[10px] font-bold text-white/70 tracking-widest uppercase">
            {isTransmitting ? 'Transmitting' : 'Listening'}
          </span>
        </div>
      )}
    </div>
  );
}
