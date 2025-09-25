const express = require('express');
const router = express.Router();

// Single line commented endpoints - should be filtered
// app.get('/single-line-comment', (req, res) => { res.json({ message: 'filtered' }); });
// router.post('/another-single-line', (req, res) => { res.json({ message: 'filtered' }); });

/* Block commented endpoints - should be filtered */
/* app.put('/block-comment', (req, res) => { res.json({ message: 'filtered' }); }); */

/*
 * Multi-line block commented endpoints - should be filtered
 * router.delete('/multi-line-block', (req, res) => { res.json({ message: 'filtered' }); });
 * app.patch('/another-multi-line', (req, res) => { res.json({ message: 'filtered' }); });
 */

/**
 * JSDoc commented endpoints - should be filtered
 * app.get('/jsdoc-comment', (req, res) => { res.json({ message: 'filtered' }); });
 */

// Active endpoints - should NOT be filtered
app.get('/active', (req, res) => {
  res.json({ message: 'active' });
});

router.post('/users', (req, res) => {
  res.json({ message: 'created' });
});

// Mixed scenarios
/*
app.get('/mixed-block', (req, res) => {
  res.json({ message: 'filtered' });
});
*/

// router.get('/commented-inline', (req, res) => { res.json({ message: 'filtered' }); }); // This should be filtered

app.patch('/active-after-comment', (req, res) => {
  res.json({ message: 'active' }); // This should NOT be filtered
});

// Different patterns
// app.route('/commented-route').get((req, res) => { res.json({ message: 'filtered' }); });

app.route('/active-route')
  .get((req, res) => { res.json({ message: 'active' }); })
  .post((req, res) => { res.json({ message: 'active' }); });

module.exports = router;