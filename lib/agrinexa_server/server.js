const express = require('express');
const axios = require('axios');
const app = express();

app.use(express.json());

const PUBLIC_KEY = 'pk.uwjbNofcQJKSkxnGGy3U765lwyXZVv4uSMMUiZ79bcfuPxrnCn9e42dDpZSoo66Z1XMNM9nGigzVjxtt5vbo3RcGYoH7bVqgkJtjlnyHO8eGyZDI9vMqE5k9rTLL4';
const PRIVATE_KEY = 'sk.JUuM6bpBuAFg3ZDoMnBrEqdGcagtS31IldwGzGBeUGw8Gif4Gapn8tVadIUUFhwigHnzQgY9TpzFaTBJJhmNZzAnezlIbTz4zCZ0Af7GlejC5spCWzEeY4Ilt1fYJ';

// Health check
app.get('/', (req, res) => {
  res.json({ status: 'AgriNexa payment server is running' });
});

// Transfer money to seller
app.post('/transfer', async (req, res) => {
  const { amount, destination, channel, description, reference } = req.body;
  if (!amount || !destination || !channel) {
    return res.status(400).json({ error: 'Missing required fields' });
  }
  try {
    const response = await axios.post(
      'https://api.notchpay.co/transfers',
      { amount, currency: 'XAF', description, reference, destination, channel },
      {
        headers: {
          'Authorization': PUBLIC_KEY,
          'X-Grant': PRIVATE_KEY,
          'Content-Type': 'application/json',
        },
      }
    );
    res.json({ success: true, data: response.data });
  } catch (error) {
    const msg = error.response?.data?.message || error.message;
    res.status(500).json({ success: false, error: msg });
  }
});

// Verify payment status
app.get('/verify/:reference', async (req, res) => {
  try {
    const response = await axios.get(
      `https://api.notchpay.co/payments/${req.params.reference}`,
      { headers: { 'Authorization': PUBLIC_KEY } }
    );
    res.json({ success: true, data: response.data });
  } catch (error) {
    const msg = error.response?.data?.message || error.message;
    res.status(500).json({ success: false, error: msg });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
