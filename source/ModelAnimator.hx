class ModelAnimator
{
    public var current:String;
    public var time:Float = 0;

    public function play(name:String)
    {
        current = name;
        time = 0;
    }

    public function update(dt:Float)
    {
        time += dt;
        // Apply bone transforms
    }
}
