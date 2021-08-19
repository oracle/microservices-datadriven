'use strict';

let iter = 0;

module.exports = {
  generateOrderID
};

function generateOrderID(userContext, events, done) {
  let run = Number(userContext.vars.$processEnvironment.RUN);
  let vu = Number(userContext.vars.$processEnvironment.VU);
  iter++;
  userContext.vars.orderid = (10000000 * run + 100000 * vu + iter).toString();
  return done();
}
