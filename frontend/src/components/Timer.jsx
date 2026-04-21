import React, { useState, useEffect } from 'react';

export default function Timer({ deadline, onExpire }) {
  const [timeLeft, setTimeLeft] = useState(null);
  useEffect(() => {
    if (!deadline) return;
    const interval = setInterval(() => {
      const diff = new Date(deadline) - new Date();
      if (diff <= 0) {
        clearInterval(interval);
        setTimeLeft({ minutes: 0, seconds: 0 });
        onExpire?.();
      } else {
        const minutes = Math.floor(diff / 60000);
        const seconds = Math.floor((diff % 60000) / 1000);
        setTimeLeft({ minutes, seconds });
      }
    }, 1000);
    return () => clearInterval(interval);
  }, [deadline, onExpire]);
  if (!timeLeft) return <div className="text-center text-gray-400">--:--</div>;
  return (
    <div className="text-center font-mono text-3xl font-bold text-purple-400">
      {String(timeLeft.minutes).padStart(2, '0')}:{String(timeLeft.seconds).padStart(2, '0')}
    </div>
  );
}