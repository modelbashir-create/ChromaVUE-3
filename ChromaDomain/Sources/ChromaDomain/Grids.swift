// Domain/Grids.swift

/// A scalar field sampled on a regular 2D grid (row-major).
public struct ScalarGrid: Hashable, Codable, Sendable {
    public let width: Int
    public let height: Int
    public let values: [Float]   // length = width * height

    public init(width: Int, height: Int, values: [Float]) {
        precondition(width > 0 && height > 0, "Grid dimensions must be positive")
        precondition(values.count == width * height, "values.count must equal width * height")
        self.width = width
        self.height = height
        self.values = values
    }

    @inline(__always)
    public func index(x: Int, y: Int) -> Int {
        y * width + x
    }

    public subscript(x: Int, y: Int) -> Float {
        values[index(x: x, y: y)]
    }
}

/// A depth map sampled on a regular 2D grid (row-major), in millimetres.
public struct DepthGrid: Hashable, Codable, Sendable {
    public let width: Int
    public let height: Int
    public let values: [Float]   // length = width * height, depth in mm

    public init(width: Int, height: Int, values: [Float]) {
        precondition(width > 0 && height > 0, "Grid dimensions must be positive")
        precondition(values.count == width * height, "values.count must equal width * height")
        self.width = width
        self.height = height
        self.values = values
    }

    @inline(__always)
    public func index(x: Int, y: Int) -> Int {
        y * width + x
    }

    public subscript(x: Int, y: Int) -> Float {
        values[index(x: x, y: y)]
    }
}

/// Single RGB pixel (linear space, 0–1).
public struct RGBPixel: Hashable, Codable, Sendable {
    public let r: Float
    public let g: Float
    public let b: Float

    public init(r: Float, g: Float, b: Float) {
        self.r = r
        self.g = g
        self.b = b
    }
}

/// An RGB image sampled on a regular 2D grid (row-major).
public struct RGBGrid: Hashable, Codable, Sendable {
    public let width: Int
    public let height: Int
    public let pixels: [RGBPixel]   // length = width * height

    public init(width: Int, height: Int, pixels: [RGBPixel]) {
        precondition(width > 0 && height > 0, "Grid dimensions must be positive")
        precondition(pixels.count == width * height, "pixels.count must equal width * height")
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    @inline(__always)
    public func index(x: Int, y: Int) -> Int {
        y * width + x
    }

    public subscript(x: Int, y: Int) -> RGBPixel {
        pixels[index(x: x, y: y)]
    }
}
