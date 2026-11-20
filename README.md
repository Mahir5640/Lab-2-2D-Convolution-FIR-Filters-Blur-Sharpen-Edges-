# Lab 2 — 2D Convolution & FIR Filters

**Mahir Foysol Chowdhury**  
Mathematical Algorithms (DSP) — Image Processing Labs

Run `lab2.m` in MATLAB with Image Processing Toolbox. The script prints the input source and numerical checks in the Command Window and saves the figures in `lab2_figures`.

## 1. Delta image and impulse response

I placed one nonzero pixel in the center of a 101 × 101 image and convolved it with a 3 × 3 averaging kernel. The result contains a centered 3 × 3 block whose values are all 1/9. The surrounding pixels are zero. This shows that the response to a unit impulse is the kernel itself, so the kernel is the filter's impulse response `h[m,n]`.

![Unit impulse and 3 × 3 averaging response](lab2_figures/01-impulse.png)

## 2. Box blur, Gaussian blur, and separability

The 3 × 3 box averages a small neighborhood. The 7 × 7 box averages over a larger neighborhood, so it generally smooths more detail. A box gives equal weight to every pixel inside its window. The Gaussian with sigma 1.2 gives more weight to pixels near the center and has weaker frequency-response sidelobes than a same-size box.

I applied the Gaussian both as a 7 × 7 kernel and as two 1D filters. The script reports the maximum difference between the two results, which should be near floating-point roundoff when both use replicate padding.

![Original image and three low-pass results](lab2_figures/02-low-pass.png)

## 3. Unsharp masking

I subtracted the Gaussian-blurred image from the original to isolate fine detail. In the signed mask, mid-gray represents zero, brighter pixels represent positive values, and darker pixels represent negative values. I added the mask back to the original with gain 1.0 and clipped the result to [0, 1]. This increases local contrast around edges, making them look sharper.

![Original, Gaussian blur, signed detail mask, and sharpened result](lab2_figures/03-unsharp.png)

## 4. Sobel and Laplacian edges

Sobel `Gx` measures intensity changes across columns and responds strongly to vertical edges. Sobel `Gy` measures changes across rows and responds strongly to horizontal edges. `hypot(Gx, Gy)` combines them into a nonnegative gradient magnitude that highlights edges in any direction.

The Laplacian measures second spatial derivatives. It produces positive and negative responses around sharp transitions. Mid-gray represents zero in the signed Sobel and Laplacian panels.

![Sobel directional responses, gradient magnitude, and Laplacian](lab2_figures/04-edges.png)

## 5. Correlation vs convolution

Correlation applies the kernel as written. Convolution rotates it by 180° before applying it. The box kernel is unchanged by rotation, so `conv2` and `imfilter` in convolution mode should agree up to numerical roundoff when both use zero padding and return the same output size.

Rotating the horizontal Sobel kernel reverses its sign. With identical padding, its convolution and correlation results therefore have opposite signs. Bright and dark responses swap in the figure, and their sum should be near zero.

![Sobel correlation, convolution, and absolute difference](lab2_figures/05-kernel-flip.png)

## 6. Boundary handling

The figure magnifies the top-left corner after 7 × 7 box filtering. Replicate padding extends the image using its closest border pixels. Symmetric padding reflects nearby pixels across the image boundary. Circular padding wraps around to pixels on the opposite side, which can introduce a visible seam when opposite edges have different intensities. The differences affect pixels within three samples of a border.

![Magnified corner comparison for replicate, symmetric, and circular padding](lab2_figures/06-boundaries.png)

## 7. Reflections

1. **Why prefer a Gaussian over a large box filter?** A box has an abrupt cutoff at the edges of its kernel and a frequency response with sidelobes. Gaussian weights taper toward the edges, which gives a smoother frequency response and weaker sidelobes.
2. **How does separability reduce computation?** A direct 7 × 7 filter uses 49 kernel taps per output pixel. Two length-7 passes use approximately 14 taps per pixel in total and produce the same Gaussian result up to roundoff.
3. **How do boundary modes change corners and edges?** Replicate repeats the border, symmetric uses a reflected neighborhood, and circular brings in pixels from the opposite side. Corners can show stronger differences because the kernel extends outside the image in both directions.
