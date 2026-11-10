const generatePairingCode = () => {
  const digits = Math.floor(1000 + Math.random() * 9000);
  return `KS-${digits}`;
};

module.exports = { generatePairingCode };

