package backend.model;

import openfl.display3D.Context3D;
import openfl.geom.Matrix3D;
import lime.math.Vector3;

class Model3D
{
    public var transform:Matrix3D;
    public var position:Vector3;
    public var rotation:Vector3;
    public var scale:Vector3;

    public function new()
    {
        transform = new Matrix3D();
        position = new Vector3();
        rotation = new Vector3();
        scale = new Vector3(1,1,1);
    }

    public function update()
    {
        transform.identity();
        transform.appendScale(scale.x, scale.y, scale.z);
        transform.appendRotation(rotation.x, Vector3.X_AXIS);
        transform.appendRotation(rotation.y, Vector3.Y_AXIS);
        transform.appendRotation(rotation.z, Vector3.Z_AXIS);
        transform.appendTranslation(position.x, position.y, position.z);
    }

    public function draw(ctx:Context3D) {}
}
