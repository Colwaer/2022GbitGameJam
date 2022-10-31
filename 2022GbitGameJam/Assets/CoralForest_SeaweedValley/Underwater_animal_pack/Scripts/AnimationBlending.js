var Anims:AnimationClip[];
var fadeTime:float;

function Start()
{
animation.Play("swim");
}

function Update()
{ 
if(Input.GetButtonDown("Fire1"))
	{
	animation.CrossFade("eat",1);
	}
 if(Input.GetButtonUp("Fire1"))
	{
	animation.CrossFade("swim",1);
	//Switch2toStop();
	//Switch1toPlay();
	}
}


function Switch1toStop () 
{
animation.Blend(Anims[1].name,0,fadeTime);
}

function Switch2toStop ()
{
animation.Blend(Anims[2].name,0,fadeTime);
}

function Switch3toStop ()
{
animation.Blend(Anims[3].name,0,fadeTime);
}

function Switch1toPlay ()
{
animation.Blend(Anims[1].name,1,fadeTime);
}

function Switch2toPlay ()
{
animation.Blend(Anims[2].name,1,fadeTime);
}

function Switch3toPlay ()
{
animation.Blend(Anims[3].name,1,fadeTime);
}


