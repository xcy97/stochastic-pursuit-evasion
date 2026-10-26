"""Evaluate manuscript Eq. (25), without stochastic simulation.
Gauss-Legendre quadrature for R<=y<=r0 and Gauss-Laguerre for z>=y,
using z=y+(D/v)*u, v=a/mu. The exponential is evaluated with expm1.
Defaults match the manuscript R=.1, S=1, ve=1, r0=1.
This is the aligned, quasi-steady model C, not an exact formula for model A.
"""
from pathlib import Path
import argparse,csv
import numpy as np
from numpy.polynomial.legendre import leggauss
from numpy.polynomial.laguerre import laggauss
def theory(D, mu, a, n=160):
    v = a / mu
    R = 0.1
    S = 1.0
    ve = 1.0
    r0 = 1.0
    x, w = leggauss(n)
    u, q = laggauss(n)
    y = ((r0 - R) / 2 * x + (r0 + R) / 2)[:, None]
    z = y + D / v * u
    exponent = np.log(q)[None, :] + ve * S * np.exp(-(y - R) / S) * (-np.expm1(-D / v * u / S))[None, :] / D
    return float((r0 - R) / 2 / v * np.sum(w * np.sum(z * np.exp(exponent), axis=1) / y[:, 0]))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--mu',type=float,default=3.);p.add_argument('--a',type=float,default=2.4)
 p.add_argument('--D',type=float,nargs='+',default=[.002154,.004642,.021544,.215443,31.6228]);args=p.parse_args()
 if args.mu<=0 or args.a<=0 or min(args.D)<=0:p.error('mu, a and D must be positive')
 print('mu,a,D,T_128,T_160,relative_change')
 for d in args.D:
  x=theory(d,args.mu,args.a,128);y=theory(d,args.mu,args.a,160)
  print(f'{args.mu},{args.a},{d},{x:.12g},{y:.12g},{abs(y/x-1):.8g}')
