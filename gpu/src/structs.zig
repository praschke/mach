//! Structures which are not ABI compatible with webgpu.h
const Buffer = @import("Buffer.zig");
const Sampler = @import("Sampler.zig");
const TextureView = @import("TextureView.zig");
const BufferBindingType = @import("enums.zig").BufferBindingType;

pub const BindGroupEntry = struct {
    binding: u32,
    buffer: Buffer,
    offset: u64,
    size: u64,
    sampler: Sampler,
    texture_view: TextureView,
};

pub const BufferBindingLayout = struct {
    type: BufferBindingType,
    has_dynamic_offset: bool,
    min_binding_size: u64,
}

test "syntax" {
    _ = BindGroupEntry;
    _ = BufferBindingLayout;
}